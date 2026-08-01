extends Node
class_name BoidObstacleAvoider

@export var body: CharacterBody3D
@export var shapecast: ShapeCast3D

@export var look_ahead := 2.0
@export var avoidance_strength := 10.0
@export var max_force := 5.0
@export var max_speed := 7.0

var avoidance_force := Vector3.ZERO


func _ready():
	shapecast.target_position = Vector3.ZERO

func _physics_process(delta: float) -> void:
	_update_cast()
	_compute_avoidance()
	_apply_movement(delta)

func _update_cast():
	var dir = body.velocity
	if dir.length() < 0.001:
		dir = -body.global_transform.basis.z

	dir = dir.normalized()

	shapecast.global_transform = body.global_transform
	shapecast.target_position = dir * look_ahead
	shapecast.force_shapecast_update()


func _compute_avoidance():
	avoidance_force = Vector3.ZERO

	var count = shapecast.get_collision_count()
	if count == 0:
		return

	var forward = -body.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	for i in range(count):
		var collider = shapecast.get_collider(i)

		if collider is CharacterBody3D:
			continue

		if collider.is_in_group("floor"):
			continue

		var normal = shapecast.get_collision_normal(i)
		var point = shapecast.get_collision_point(i)

		normal.y = 0
		if normal.length() < 0.001:
			continue
		normal = normal.normalized()

		# 1) hard push out (fixes corner penetration lock)
		var push = normal

		# 2) slide along wall
		var slide = normal.cross(Vector3.UP).normalized()

		if slide.dot(forward) < 0:
			slide = -slide

		# 3) extra escape from actual corner geometry
		var to_point = (body.global_position - point)
		to_point.y = 0
		if to_point.length() > 0.001:
			to_point = to_point.normalized()
			push += to_point * 0.5

		avoidance_force += push * 0.6
		avoidance_force += slide * 0.4

	if avoidance_force.length() > 0.001:
		avoidance_force = avoidance_force.normalized()
func _apply_movement(delta):
	var steering = avoidance_force * avoidance_strength

	steering = steering.limit_length(max_force)
	print("steering =", steering)
	steering.y = 0.0

	body.velocity += steering * delta
	body.velocity = body.velocity.limit_length(max_speed)
