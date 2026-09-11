extends BTNode
class_name BTConditionCanSeePlayer


func tick(actor: Node, blackboard: Dictionary) -> Status:
	for child in actor.get_children():
		if child is VisionCone:
			if child.player_in_cone == true:
				blackboard["target"] = child.target
				print (blackboard["target"])
				return Status.SUCCESS
				print("sees player bt condition")
			else:
				blackboard.erase("target")
				return Status.FAILURE
				print("fails to see player btcondition")

	return Status.FAILURE
