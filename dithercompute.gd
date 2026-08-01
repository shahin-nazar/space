extends Node
class_name DitherCompute1
 
## Attach to a plain Node. Wire up the two exports in the inspector.
 
@export var source_viewport: SubViewport
@export var output_rect: TextureRect
@export var ab_scale: float = 0.7
 
## Fill this with your palette as hex strings, e.g. ["#D94A8E", "#A05684", ...]
## palette_lab is derived automatically from these — see _build_palette().
## If you later want "fake" search points, add entries to fake_lab_overrides
## keyed by index (0-based) with a Vector3(L, a, b) that differs from the
## real color's own OKLab — the shader will still draw the real palette_rgb.
@export var palette_hex: PackedStringArray = PackedStringArray()
@export var fake_lab_overrides: Dictionary = {} # int index -> Vector3(L,a,b)
 
var rd: RenderingDevice
var shader_rid: RID
var pipeline_rid: RID
var out_image_rid: RID
var error_image_rid: RID
var palette_lab_buf: RID
var palette_rgb_buf: RID
var sampler_rid: RID
var tex_size: Vector2i
var palette_count: int
var display_tex: Texture2DRD
 
func _ready() -> void:
	rd = RenderingServer.get_rendering_device()
	tex_size = source_viewport.size
 
	var shader_file: RDShaderFile = load("res://postprocessing/dither_diffusion.glsl")
	var spirv: RDShaderSPIRV = shader_file.get_spirv()
	shader_rid = rd.shader_create_from_spirv(spirv)
	pipeline_rid = rd.compute_pipeline_create(shader_rid)
 
	var out_fmt := RDTextureFormat.new()
	out_fmt.width = tex_size.x
	out_fmt.height = tex_size.y
	out_fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	out_fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
		| RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT \
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	out_image_rid = rd.texture_create(out_fmt, RDTextureView.new())
 
	var err_fmt := RDTextureFormat.new()
	err_fmt.width = tex_size.x
	err_fmt.height = tex_size.y
	err_fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	err_fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT \
		| RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT
	error_image_rid = rd.texture_create(err_fmt, RDTextureView.new())
 
	sampler_rid = rd.sampler_create(RDSamplerState.new())
 
	_build_palette()
 
	display_tex = Texture2DRD.new()
	display_tex.texture_rd_rid = out_image_rid
	output_rect.texture = display_tex
 
## --- palette building ------------------------------------------------------
 
func hex_to_rgb01(hex: String) -> Vector3:
	var h := hex.strip_edges().trim_prefix("#")
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
	var l_ = sign(l) * pow(abs(l), 1.0 / 3.0)
	var m_ = sign(m) * pow(abs(m), 1.0 / 3.0)
	var s_ = sign(s) * pow(abs(s), 1.0 / 3.0)
	return Vector3(
		0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
		1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
		0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
	)
 
func _build_palette() -> void:
	palette_count = palette_hex.size()
	var lab_data := PackedFloat32Array()
	var rgb_data := PackedFloat32Array()
 
	for i in range(palette_count):
		var rgb01 := hex_to_rgb01(palette_hex[i])
		var lab := rgb01_to_oklab(rgb01)
		if fake_lab_overrides.has(i):
			lab = fake_lab_overrides[i]
 
		lab_data.append(lab.x); lab_data.append(lab.y); lab_data.append(lab.z); lab_data.append(0.0)
		rgb_data.append(rgb01.x); rgb_data.append(rgb01.y); rgb_data.append(rgb01.z); rgb_data.append(0.0)
 
	palette_lab_buf = rd.storage_buffer_create(lab_data.size() * 4, lab_data.to_byte_array())
	palette_rgb_buf = rd.storage_buffer_create(rgb_data.size() * 4, rgb_data.to_byte_array())
 
## --- per-frame dispatch -----------------------------------------------------
 
func _process(_delta: float) -> void:
	rd.texture_clear(error_image_rid, Color(0, 0, 0, 0), 0, 1, 0, 1)
 
	var src_rid: RID = RenderingServer.texture_get_rd_texture(source_viewport.get_texture().get_rid())
 
	var u0 := RDUniform.new()
	u0.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	u0.binding = 0
	u0.add_id(sampler_rid)
	u0.add_id(src_rid)
 
	var u1 := RDUniform.new()
	u1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u1.binding = 1
	u1.add_id(out_image_rid)
 
	var u2 := RDUniform.new()
	u2.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u2.binding = 2
	u2.add_id(palette_lab_buf)
 
	var u3 := RDUniform.new()
	u3.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	u3.binding = 3
	u3.add_id(palette_rgb_buf)
 
	var u4 := RDUniform.new()
	u4.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	u4.binding = 4
	u4.add_id(error_image_rid)
 
	var uniform_set := rd.uniform_set_create([u0, u1, u2, u3, u4], shader_rid, 0)
 
	var push := PackedByteArray()
	push.resize(16)
	push.encode_s32(0, tex_size.x)
	push.encode_s32(4, tex_size.y)
	push.encode_s32(8, palette_count)
	push.encode_float(12, ab_scale)
 
	var list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(list, pipeline_rid)
	rd.compute_list_bind_uniform_set(list, uniform_set, 0)
	rd.compute_list_set_push_constant(list, push, push.size())
	rd.compute_list_dispatch(list, 1, 1, 1) # single invocation, walks the whole image serially
	rd.compute_list_end()
 
	rd.free_rid(uniform_set)
