extends Node
class_name CPUDitherCompute

## Attach to a plain Node. Replaces the RenderingDevice compute pipeline —
## this does the same OKLab + palette + Floyd-Steinberg work, but on a
## background CPU thread, so it costs zero main-thread frame time. The
## tradeoff: the dithered view updates at its own (slower) pace, decoupled
## from your actual game framerate, instead of every rendered frame.

@export var source_viewport: SubViewport
@export var output_rect: TextureRect

## Internal working resolution for the dither pass — independent of your
## SubViewport's own resolution. Keep this small (pixel-art scale); it's
## the dominant cost driver since the algorithm is O(width * height).
@export var work_width: int = 240
@export var work_height: int = 135

## How often (in seconds) to kick off a new dither pass. 1/12 = 12 times a
## second; raise this (slower updates) if you want even less CPU cost.
@export var update_interval: float = 1.0 / 12.0

@export var palette_hex: PackedStringArray = PackedStringArray()
@export var ab_scale: float = 0.7
@export var err_l_scale: float = 0.8
@export var err_ab_scale: float = 0.6
@export var blend_amount: float = 0.5 # 0 = original colors, 1 = full dither

var palette_rgb: Array = []
var palette_lab: Array = []

var worker_thread: Thread
var thread_busy := false
var time_since_update := 0.0
var out_texture: ImageTexture

func _ready() -> void:
	_build_palette()
	out_texture = ImageTexture.new()
	output_rect.texture = out_texture

## --- palette building (same conversion logic as the GPU version) ----------

func hex_to_rgb01(hex: String) -> Vector3:
	var h := hex.strip_edges().trim_prefix("#")
	if h.length() != 6 or not h.is_valid_hex_number():
		push_warning("palette_hex entry '%s' is not a valid 6-digit hex color, defaulting to magenta" % hex)
		return Vector3(1.0, 0.0, 1.0)
	var r := h.substr(0, 2).hex_to_int() / 255.0
	var g := h.substr(2, 2).hex_to_int() / 255.0
	var b := h.substr(4, 2).hex_to_int() / 255.0
	return Vector3(r, g, b)

func _srgb_to_linear1(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)

func rgb01_to_oklab(c: Vector3) -> Vector3:
	var lin := Vector3(_srgb_to_linear1(c.x), _srgb_to_linear1(c.y), _srgb_to_linear1(c.z))
	var l := 0.4122214708 * lin.x + 0.5363325363 * lin.y + 0.0514459929 * lin.z
	var m := 0.2119034982 * lin.x + 0.6806995451 * lin.y + 0.1073969566 * lin.z
	var s := 0.0883024619 * lin.x + 0.2817188376 * lin.y + 0.6299787005 * lin.z
	var l_ := sign(l) * pow(abs(l), 1.0 / 3.0)
	var m_ := sign(m) * pow(abs(m), 1.0 / 3.0)
	var s_ := sign(s) * pow(abs(s), 1.0 / 3.0)
	return Vector3(
		0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
		1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
		0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
	)

func _build_palette() -> void:
	palette_rgb.clear()
	palette_lab.clear()
	for hex in palette_hex:
		var rgb01 := hex_to_rgb01(hex)
		palette_rgb.append(rgb01)
		palette_lab.append(rgb01_to_oklab(rgb01))

## --- per-frame trigger ------------------------------------------------------

func _process(delta: float) -> void:
	time_since_update += delta
	if time_since_update < update_interval:
		return
	time_since_update = 0.0

	if thread_busy:
		return # previous pass still running — skip this tick rather than overlap

	var vp_img: Image = source_viewport.get_texture().get_image()
	if vp_img == null:
		return
	vp_img.resize(work_width, work_height, Image.INTERPOLATE_BILINEAR)
	vp_img.convert(Image.FORMAT_RGBA8)

	thread_busy = true
	worker_thread = Thread.new()
	worker_thread.start(_dither_worker.bind(vp_img))

## --- background thread: the actual dithering work --------------------------

func _dither_worker(src_img: Image) -> void:
	var w := src_img.get_width()
	var h := src_img.get_height()
	var src_data: PackedByteArray = src_img.get_data() # RGBA8, 4 bytes/pixel

	var out_data := PackedByteArray()
	out_data.resize(src_data.size())

	var err_l := PackedFloat32Array()
	var err_a := PackedFloat32Array()
	var err_b := PackedFloat32Array()
	err_l.resize(w * h)
	err_a.resize(w * h)
	err_b.resize(w * h)

	var pcount := palette_lab.size()

	for y in range(h):
		for x in range(w):
			var idx := y * w + x
			var o := idx * 4
			var r := src_data[o] / 255.0
			var g := src_data[o + 1] / 255.0
			var b := src_data[o + 2] / 255.0
			var a := src_data[o + 3]

			var lab := rgb01_to_oklab(Vector3(r, g, b))
			lab.x += err_l[idx]
			lab.y += err_a[idx]
			lab.z += err_b[idx]

			var best_d := INF
			var best_i := 0
			for i in range(pcount):
				var pl: Vector3 = palette_lab[i]
				var dl := lab.x - pl.x
				var da := (lab.y - pl.y) * ab_scale
				var db := (lab.z - pl.z) * ab_scale
				var d := dl * dl + da * da + db * db
				if d < best_d:
					best_d = d
					best_i = i

			var chosen_rgb: Vector3 = palette_rgb[best_i]
			var chosen_lab := rgb01_to_oklab(chosen_rgb)

			var err := lab - chosen_lab
			err.x = clamp(err.x, -0.16, 0.16) * err_l_scale
			err.y = clamp(err.y, -0.16, 0.16) * err_ab_scale
			err.z = clamp(err.z, -0.16, 0.16) * err_ab_scale

			if x + 1 < w:
				var ni := idx + 1
				err_l[ni] += err.x * (7.0 / 16.0)
				err_a[ni] += err.y * (7.0 / 16.0)
				err_b[ni] += err.z * (7.0 / 16.0)
			if y + 1 < h:
				if x - 1 >= 0:
					var ni2 := idx + w - 1
					err_l[ni2] += err.x * (3.0 / 16.0)
					err_a[ni2] += err.y * (3.0 / 16.0)
					err_b[ni2] += err.z * (3.0 / 16.0)
				var ni3 := idx + w
				err_l[ni3] += err.x * (5.0 / 16.0)
				err_a[ni3] += err.y * (5.0 / 16.0)
				err_b[ni3] += err.z * (5.0 / 16.0)
				if x + 1 < w:
					var ni4 := idx + w + 1
					err_l[ni4] += err.x * (1.0 / 16.0)
					err_a[ni4] += err.y * (1.0 / 16.0)
					err_b[ni4] += err.z * (1.0 / 16.0)

			var final_rgb: Vector3 = Vector3(r, g, b).lerp(chosen_rgb, blend_amount)

			out_data[o] = int(clamp(final_rgb.x, 0.0, 1.0) * 255.0)
			out_data[o + 1] = int(clamp(final_rgb.y, 0.0, 1.0) * 255.0)
			out_data[o + 2] = int(clamp(final_rgb.z, 0.0, 1.0) * 255.0)
			out_data[o + 3] = a

	var result_img := Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, out_data)
	call_deferred("_apply_result", result_img)

func _apply_result(img: Image) -> void:
	out_texture.set_image(img)
	worker_thread.wait_to_finish()
	thread_busy = false
