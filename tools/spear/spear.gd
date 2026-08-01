extends RigidBody3D

var spear_force := .1
var item_id = "spear"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	body_entered.connect(on_body_entered)

func use():
	freeze = false
	gravity_scale = 1.0
	var direction = -global_transform.basis.x.normalized()
	apply_central_impulse(direction * spear_force)
	

func on_body_entered(body):
	if body.is_in_group("player"):
		return
		
	if body is CSGCombiner3D or body is StaticBody3D:
		print("Help me stepbro I'm stuck!")
		stick_to_wall()
		
	if body.has_method("take_hit"):
		body.take_hit(linear_velocity, global_transform.basis.z)
		stick_to_wall()
		
	
func stick_to_wall():
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = true
	global_position -= -global_transform.basis.z * 0.2
