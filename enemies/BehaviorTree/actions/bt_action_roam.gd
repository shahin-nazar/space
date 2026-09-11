extends BTNode
class_name BTActionRoam

var wander_target : Vector3
var timer := 0.0

func tick(actor: Node, blackboard: Dictionary) -> Status:
	timer -= actor.get_physics_process_delta_time()

	if timer <= 0.0:
		wander_target = actor.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		timer = 5.0
	
	var direction = (wander_target - actor.global_position)
	if direction.length() < 0.5:
		return Status.SUCCESS

	
	actor.velocity = direction. normalized() * 1.5
	return Status.RUNNING



	