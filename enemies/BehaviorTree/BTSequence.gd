extends BTComposite
class_name BTSequence


func tick(actor: Node, blackboard: Dictionary) -> Status:
	for child in children:
		var result := child.tick(actor, blackboard)
		if result !=  Status.SUCCESS:
			return result # stop immediately on failure or running
	return Status.SUCCESS # only reached if every child succeeded

# for example: canseeplayer > chaseplaer > attackplayer. If it can't see the player, then it willstop the whole branch.