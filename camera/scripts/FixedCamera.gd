extends Camera3D

@onready var target : RigidBody3D
@onready var trigger_component : Area3D

@export_category (" Offsets")
@export var follow_speed := 8.0
@export var set_offset : bool
@export var offset := Vector3(0, 2, -5)

@export_category("axis locks")
@export var follow_x := true
@export var follow_y := true
@export var follow_z := true
@export var follow_rotation := true
@export var lock_rotation_x := false
@export var lock_rotation_y := false
@export var lock_rotation_z := false

#yay!

func _ready():
	for child in get_children():
		if child is Area3D:
			trigger_component = child
			
	current = false
	trigger_component.trigger_state.connect(switch_camera)
	target = get_tree().get_first_node_in_group("player")

func switch_camera(in_trigger: bool):
	current = in_trigger

func _physics_process(delta):
	camera_follow(delta)

func camera_follow(delta):
	var target_pos : Vector3

	if target == null:
		return
	
	if set_offset == true:
		target_pos = target.global_position + offset
		smooth_follow_target(target_pos, delta)
	
	if set_offset == false:
		target_pos = global_position

	linear_axis_lock()

	if follow_rotation:
		var old_rot = rotation

		look_at(target.global_position, Vector3.UP)

		var new_rot = rotation

		if lock_rotation_x:
			new_rot.x = old_rot.x
		if lock_rotation_y:
			new_rot.y = old_rot.y
		if lock_rotation_z:
			new_rot.z = old_rot.z

		rotation = new_rot
		

func linear_axis_lock():
		# apply axis locks to position follow
	if follow_x:
		global_position.x = target.global_position.x + offset.x
	if follow_y:
		global_position.y = target.global_position.y + offset.y
	if follow_z:
		global_position.z = target.global_position.z + offset.z
	else:
		return
	

func smooth_follow_target(target_pos, delta):
	global_position = global_position.lerp(
	target_pos,
	1.0 - exp(-follow_speed * delta)
	)
