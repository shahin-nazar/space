extends Node
class_name BoidController

@export var body: CharacterBody3D
@export var shapecast: ShapeCast3D

@export var separation_strength := 5.0
@export var alignment_strength := 4.0
@export var cohesion_strength := 5.0
@export var max_speed := 5.0
@export var max_force := 5.0

var separation_force: Vector3 = Vector3.ZERO
var alignment_force: Vector3 = Vector3.ZERO
var cohesion_force: Vector3 = Vector3.ZERO


func _ready():
	# Ensure ShapeCast behaves as overlap volume
	shapecast.target_position = Vector3.ZERO



func _update_shapecast():
	# critical step missing in your version
	shapecast.global_transform = body.global_transform
	shapecast.force_shapecast_update()


func _compute_boids():
	var count = shapecast.get_collision_count()

	separation_force = Vector3.ZERO
	alignment_force = Vector3.ZERO
	cohesion_force = Vector3.ZERO

	if count == 0:
		return

	var center_of_mass := Vector3.ZERO
	var avg_velocity := Vector3.ZERO
	var valid := 0

	for i in range(count):
		var collider = shapecast.get_collider(i)
		#print("collider = ", collider)

		if collider == body:
			continue
		if collider.is_in_group("player"):
			continue
		if not collider is CharacterBody3D:
			continue

		var offset = collider.global_position - body.global_position
		var dist = offset.length()
		if dist < 0.001:
			continue

		# separation
		separation_force += (-offset.normalized()) * (1.0 / dist)

		# alignment
		avg_velocity += collider.velocity

		# cohesion
		center_of_mass += collider.global_position

		valid += 1

	if valid == 0:
		return

	center_of_mass /= valid
	avg_velocity /= valid

	cohesion_force = (center_of_mass - body.global_position).normalized()

	if avg_velocity.length() > 0.001:
		alignment_force = avg_velocity.normalized()


	if separation_force.length() > 0.001:
		separation_force = separation_force.normalized()


func apply_boid_forces(delta):
	var steering = (
		separation_force * separation_strength +
		alignment_force * alignment_strength +
		cohesion_force * cohesion_strength
	)

	steering.y = 0.0
	steering = steering.limit_length(max_force)

	body.velocity += steering * delta
	body.velocity = body.velocity.limit_length(max_speed)
	
	# face direction
	if body.velocity.length_squared() > 0.001:
		var target = body.global_position + body.velocity
		target.y = body.global_position.y
		body.look_at(target, Vector3.UP, false)
