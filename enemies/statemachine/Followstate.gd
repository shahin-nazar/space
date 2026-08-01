extends State
class_name Follow

@export_category("Core Nodes")
@export var enemy : CharacterBody3D
var target : CharacterBody3D

@export_category("External Params")
var sees_player : bool

@export_category(("Internal Params"))
@export var speed := 5.0
@export var turn_speed := 50

func enter():
	print("ENTER FOLLOW")
	
func physics_update(_delta: float):
	#print("sees player")
	if enemy == null or target == null:
		return

	if sees_player:
		follow()
		

func follow():
	enemy.look_at(target.global_position)
	var direction = target.global_position - enemy.global_position
	direction.y = 0
	var distance = direction.length()
	direction = direction.normalized()
	
	enemy.velocity.x = direction.x * speed
	enemy.velocity.z = direction.z * speed
	
	if distance < 3.0:
		target_found()


func target_seen(new_target: CharacterBody3D):
	print("followstate got new target")
	target = new_target
	
func target_lost():
	await get_tree().create_timer(2.0).timeout
	print("followstate lost target, transitioning to caution")
	transitioned.emit(self, "caution")

func target_found():
	transitioned.emit(self, "combat")

func exit():
	print("EXIT FOLLOW")
