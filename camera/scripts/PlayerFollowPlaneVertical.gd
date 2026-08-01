extends Camera3D
@onready var player: RigidBody3D = $"../../Player"
@export var speed := 10.0
@export var max_distance := 5
var player_position: Vector3
	
func _ready() -> void:
	# point the camera at target only once
	look_at(player.player_position, Vector3.UP)
	var player_position = player.global_transform.origin

	# store initial rotation
#	var initial_rotation = global_transform.basis
	
func follow_player_plane(delta):

	var current_pos = global_transform.origin
	
	var direction = player.global_transform - current_pos
	#direction.z = 0
	var distance = direction.length()
	
	if distance > max_distance:
		direction = direction.normalized()
		#move towards
		global_translate(direction * speed * delta)
		

#func update_position():
	#var desired_position = player_position.global_position + offset
	#global_position = desired_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	player_position = player.global_transform.origin
	follow_player_plane(delta)
