extends Camera3D

@export var player: RigidBody3D 
@export var target: Node3D
var current_pos : Vector3
var player_pos : Vector3
var target_pos : Vector3
var distance : float

@export var speed := 10.0


@export var look_at_player = false
@export var lock_x = false
@export var lock_y = false
@export var lock_z = false
@export var lock_rotation_x = false
@export var lock_rotation_y = false
@export var lock_rotation_z = false
@export var track_x = false
@export var track_y = false
@export var track_z = false

@export var smooth_speed := 5

@export var max_distance := 5
@export var max_distance_dynamic: float = 50

@export var max_camera_offset: float = 4
@export var direction_offset: float = 1.0 # set to -1 to invert


func _physics_process(delta: float) -> void:
	follow_player_rotate(delta)
	follow_player_locked_linear(delta)


	
	player_pos = player.global_transform.origin
	target_pos = target.global_transform.origin
	distance = player_pos.distance_to(current_pos)
	current_pos = global_transform.origin
	

	#z_offset()

func z_offset():
	# --- Dynamic Z distance from player ---
	distance = clamp(distance, 0.0, max_distance_dynamic)

	# 0 when far, 1 when close
	var t = 1.0 - (distance / max_distance_dynamic)
	# Move camera on Z axis relative to player
	var z_offset = t * max_camera_offset * direction_offset
	
	
	global_position.z += z_offset

	# Clamp Z so it stays at least min_distance behind the player
	var min_z = player.global_transform.origin.z + 2.0   # minimum distance behind player
	var max_z = player.global_transform.origin.z + 10.0  # maximum distance behind player

	global_position.z = clamp(global_position.z, min_z, max_z)

func follow_player_rotate(delta):
	var current_pos = global_transform.origin
	
	var direction = player_pos - current_pos
	distance = direction.length()
	
	if distance > max_distance:
		direction = direction.normalized()
		#move towards
		global_translate(direction * speed * delta)
		
	look_at(player_pos, Vector3.UP)
	
	if lock_rotation_x or lock_rotation_y or lock_rotation_z:
		var current_basis = global_transform.basis
		var euler_angles = current_basis.get_euler() # get current rotation as Euler angles
		
		if lock_rotation_x:
			euler_angles.x = 0 # lock x
		if lock_rotation_y:
			euler_angles.y = 0 # lock x
		if lock_rotation_z:
			euler_angles.z = 0 # lock x
		
		current_basis = Basis.from_euler(euler_angles)
		global_transform.basis = current_basis

func linear_lock_handler(player_position: Vector3, current_pos: Vector3):
	if lock_x:
		target_pos = Vector3(current_pos.x, player_position.y, player_position.z)
	if lock_y:
		target_pos = Vector3(player_position.x, current_pos.y, player_position.z)
	if lock_z:
		target_pos = Vector3(player_position.x, player_position.y, current_pos.z)
		
	return target_position

func follow_player_locked_linear(delta):
	var target_position = linear_lock_handler(player_pos, current_pos)
	 

	
	var new_position = current_pos.lerp(target_position, smooth_speed * delta)
	global_position = new_position
	
	direction.z = 0
	if distance > max_distance:
		direction = direction.normalized()
		global_translate(direction * speed * delta)


#func offset_camera_position(player_position: Vector3) -> Vector3:
	#var distance = player_position.distance_to(
		#target.global_transform.origin
		#)
	#
	## clamp distance so it doesn't exceed max distance
	#distance = clamp(distance, 0.0, max_distance_dynamic)
	#
	## 0 when far, 1 when close
	#var t = 1.0 - (distance / max_distance_dynamic)
	#
	## apply offset
	#var offset_x = t * max_camera_offset * direction_offset
	#
	#var desired_offset = player.global_transform.origin
	#desired_offset.x += offset_x
	#
	#return desired_offset

