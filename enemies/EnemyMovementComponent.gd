extends Node
class_name EnemyMovementComponent

@export var body: CharacterBody3D
@export var gravity = 30

var enemy_speed : Vector3


func update_movement(delta):
	if body.velocity.y > 0.0 and body.is_on_ceiling():
		body.velocity.y = 0.0

	if not body.is_on_floor():
		body.velocity.y -= gravity * delta

	body.move_and_slide()


