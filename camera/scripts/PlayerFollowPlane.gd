extends Camera3D

@onready var player: RigidBody3D = $"../Player"

@export var speed := 10.0
@export var max_distance := 5

func follow_player_rotate_plane(delta):
	var player_position = player.global_transform.origin
	var current_pos = global_transform.origin
	
	var direction = player_position - current_pos
	var distance = direction.length()
	
	if distance > max_distance:
		direction = direction.normalized()
		#move towards
		global_translate(direction * speed * delta)
		
	look_at(player_position, Vector3.UP)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	follow_player_rotate_plane(delta)
