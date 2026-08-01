extends Camera3D

@export var player: RigidBody3D 
@export var center: Vector3 = Vector3.ZERO #center of circle
@export var radius: float = 30.0
@export var height: float = 2.0

@export var inner_wall : CSGSphere3D 

func _ready():
	#print("sphere size: ", inner_wall.radius)
	#print("sphere global transform: ", inner_wall.global_transform)
	print(player, inner_wall)
	player.global_transform.origin
	update_camera_position()

func follow_player_rotate():
	var player_position = player.global_transform.origin
	look_at(player_position, Vector3.UP)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	#follow_player_rotate()
	update_camera_position()

func update_camera_position():
	# calculate direction from center of player
	var horizontal_dir = (player.global_position - center)
	horizontal_dir.y = 0 #ignore vertical difference for direction
	horizontal_dir = horizontal_dir.normalized()
	
	# calculate target position from circle
	var target_position = center + horizontal_dir * radius
	target_position.y = player.global_position.y
	
	#smoothly move camera to target position
	global_position = global_position.lerp(target_position, 10 * get_process_delta_time())
	
	# make camera look at the center
	look_at(center)
