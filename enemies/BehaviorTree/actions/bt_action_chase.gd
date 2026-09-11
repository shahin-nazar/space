extends BTNode
class_name BTActionChase

@export var speed := 5.0
@export var turn_speed := 5.0

func tick(actor: Node, blackboard: Dictionary) -> Status:
	if not blackboard.has("target"):
		return Status.FAILURE
		print("chase failure")
	
	var target: Node3D = blackboard["target"]
	actor.look_at(target.global_position)
	var direction = target.global_position - actor.global_position
	var distance = direction.length()
	direction = direction.normalized()
	
	if distance < 1.5:
		return Status.SUCCESS # close enough, done chasing
		print("chasing succes")
	

	actor.velocity.x = direction.x * speed
	actor.velocity.z = direction.z * speed

	return Status.RUNNING # still chasing, ask me again next time 
