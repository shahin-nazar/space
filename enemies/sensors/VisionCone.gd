extends Area3D
class_name VisionCone

@export_category("Necessary Nodes")
@export var cone : CollisionShape3D
@export var timer : Timer
@export var raycast : RayCast3D

@export_category("visibility")
var view_obstructed := false
var player_in_cone = false
var player_colliding := false
var was_seen := false
var tracking_player : bool

@export_category("targeting")
@export var target_is_facing_enemy : bool 
@export var current_target_position : Vector3
@export var distance_to_target : float
@export var orientation_to_target : float #???
@export var engage_range : float

var target : RigidBody3D
var direction : Vector3
var distance : float
var target_position : Vector3

signal target_seen(target: RigidBody3D)
signal target_unseen()

func _ready() -> void:
	monitoring = true
	monitorable = false
	
	#timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	raycast.enabled = true
	raycast.target_position = Vector3(0, 0, -100)
	
	#engage_range: I cannot manually 
	#change the length of the cone to set the engage range, do this later
	#init it here so each enemy has a different engage range

func _physics_process(_delta: float) -> void:
	if tracking_player and target != null:
		target_position = target.global_position
		raycast.look_at(target_position, Vector3.UP)
		raycast_check()
	

func raycast_check():
	player_colliding = false
	
	raycast.force_raycast_update()

	if raycast.is_colliding():
		
		var collider = raycast.get_collider()

		if collider.is_in_group("player"):
			player_colliding = true
			raycast.debug_shape_custom_color = Color.GREEN
			view_obstructed = false
			player_in_cone = true
			
			#get direction
			direction = target_position - global_position
			distance = direction.length()
		else:
			raycast.debug_shape_custom_color = Color.RED
			view_obstructed = true
			player_in_cone = false	
						
	if !player_colliding:
		player_in_cone = false
	
	if player_in_cone and !was_seen:
		target_seen.emit(target)
	
	elif !player_in_cone and was_seen:
		target_unseen.emit(target.global_position)
		
	was_seen = player_in_cone


func _on_body_entered(body):
	if body.is_in_group("player"):

		tracking_player = true
		target = body

		print("body entered visioncone")

func _on_body_exited(body):
	if body.is_in_group("player"):
		target_unseen.emit()
		player_in_cone = false
		tracking_player = false
		target = null
		
		print("body exited visioncone")



# @export var vision_range := 10.0
# @export var vision_angle := 45.0

# func _physics_process(_delta):
# 	var bodies = get_overlapping_bodies()

# 	for body in bodies:
# 		if body.is_in_group("player"):
# 			var to_player = body.global_position - global_position
# 			var distance = to_player.length()

# 			if distance > vision_range:
# 				continue

# 			var direction_to_player = to_player.normalized()
# 			var forward = -global_transform.basis.z

# 			var angle = rad_to_deg(acos(forward.dot(direction_to_player)))

# 			if angle <= vision_angle:
# 				# Player is inside the vision cone
# 				target = body
# 				track_player_toggle = true
# 				return

# 	target = null
# 	track_player_toggle = false