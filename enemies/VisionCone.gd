extends Area3D

@export var cone : CollisionShape3D
@export var timer : Timer
@export var raycast : RayCast3D

var target : CharacterBody3D
var direction : Vector3
var distance : float

@export var engage_range : float


var view_obstructed := false
var sees_player = false
var player_found := false
var was_seen := false

signal target_seen(target: CharacterBody3D)
signal target_unseen()

func _ready() -> void:
	monitoring = true
	monitorable = false
	
	timer.timeout.connect(_on_timer_timeout)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	raycast.enabled = true
	raycast.target_position = Vector3(0, 0, -100)
	
	#engage_range: I cannot manually 
	#change the length of the cone to set the engage range, do this later
	#init it here so each enemy has a different engage range


func _on_timer_timeout():
	player_found = false
	
	var overlaps = self.get_overlapping_bodies()

	if overlaps.size() > 0:

		for overlap in overlaps:

			if overlap is Player:
				var playerposition = overlap.global_transform.origin
				raycast.look_at(playerposition, Vector3.UP)
				raycast.force_raycast_update()

				if raycast.is_colliding():
					
					var collider = raycast.get_collider()

					if collider.is_in_group("player"):
						player_found = true
						raycast.debug_shape_custom_color = Color.GREEN
						view_obstructed = false
						sees_player = true
						target = collider
						
						#get direction
						direction = target.global_position - global_position
						distance = direction.length()
					else:
						raycast.debug_shape_custom_color = Color.RED
						view_obstructed = true
						sees_player = false	
						#target = null
						
	if !player_found:
		sees_player = false
		#target = null
	
	if sees_player and !was_seen:
		target_seen.emit(target)
	
	elif !sees_player and was_seen:
		target_unseen.emit(target.global_position)
		
	was_seen = sees_player

func _on_body_entered(body):
	if body.is_in_group("player"):
		timer.start()
		print("body entered visioncone")

func _on_body_exited(body):
	if body.is_in_group("player"):
		target_unseen.emit()
		sees_player = false
		timer.stop()
		print("body exited visioncone")
