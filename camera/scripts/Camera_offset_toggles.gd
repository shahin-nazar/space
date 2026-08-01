extends Camera3D
class_name CameraOffsetComponent


@export_category("Marker Reference")
@export var marker_path: NodePath
@export var max_distance: float = 10.0

@export_category("Curves (0–1 input)")
@export var fov_curve: Curve
@export var h_offset_curve: Curve
@export var c_offset_curve: Curve

@export var rotation_x_curve: Curve
@export var rotation_y_curve: Curve
@export var rotation_z_curve: Curve

@export_category("Base Values (fallback)")
@export var base_fov: float = 75.0
@export var base_h_offset: float = 0.0
@export var base_c_offset: float = 0.0

@export var base_rotation: Vector3 = Vector3.ZERO


var marker: Node3D


func _ready():
	if marker_path != NodePath():
		marker = get_node(marker_path) as Node3D


func _process(_delta):
	if marker == null:
		return

	set_parameters()


func get_t() -> float:
	var dist = global_position.distance_to(marker.global_position)
	return clamp(dist / max_distance, 0.0, 1.0)


func set_parameters():
	var t = get_t()

	# --- FOV ---
	if fov_curve:
		fov = fov_curve.sample(t)
	else:
		fov = base_fov

	# --- Horizontal offset ---
	if h_offset_curve:
		h_offset = h_offset_curve.sample(t)
	else:
		h_offset = base_h_offset

	# --- Center offset ---
	if c_offset_curve:
		# replace with your system (depends on how you apply it)
		# example placeholder:
		# position.x = base_c_offset + c_offset_curve.sample(t)
		pass

	# --- Rotation ---
	var rot := base_rotation

	if rotation_x_curve:
		rot.x = rotation_x_curve.sample(t)

	if rotation_y_curve:
		rot.y = rotation_y_curve.sample(t)

	if rotation_z_curve:
		rot.z = rotation_z_curve.sample(t)

	rotation = rot