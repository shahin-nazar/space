extends State
class_name Return

@export var enemy : CharacterBody3D
var target : CharacterBody3D
var start_position : Vector3

const SPEED := 5.0
const TURN_SPEED := 50

var sees_player : bool
var attack_possible = false
var can_take_dmg = true


func enter():
	print("ENTER FOLLOW")
	
func physics_update(_delta: float):
	#print("sees player")
	if enemy == null or target == null:
		return
	
	#print("target of followstate is ", target)
	var direction = start_position.global_position - enemy.global_position
	direction.y = 0

	var distance = direction.length()

	if sees_player:
		direction = direction.normalized()
		
		var rotation = enemy.global_position.direction_to(target.global_position)
		
		var angle = atan2(rotation.x, rotation.z)
		
		var current_angle = atan2(enemy.global_transform.basis.x.z, enemy.global_transform.basis.x.x)
		
		current_angle = lerp_angle(current_angle, angle, TURN_SPEED * _delta)
		
		enemy.rotation.y = current_angle
		
		#enemy.look_at(target.global_position, Vector3.UP)

		enemy.velocity.x = direction.x * SPEED
		enemy.velocity.z = direction.z * SPEED
		
		#enemy.move_and_slide()


	if !sees_player:
		transitioned.emit(self, "caution")

func target_seen(new_target: CharacterBody3D):
	target = new_target
	sees_player = true
	
func target_lost():
	sees_player = false
	target = null

func exit():
	print("EXIT FOLLOW")
