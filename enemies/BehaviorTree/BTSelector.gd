extends BTComposite
class_name BTSelector

# try each one, stop as soon as one wworks

func tick(actor: Node, blackboard: Dictionary) -> Status:
	for child in children:
		var result := child.tick(actor, blackboard)
		if result != Status.FAILURE:
			return result # stop immediately on success or runnign
	return Status.FAILURE # only reached if every child failed

# example: trychase> try attack > wander; if trychase or tryattack fail, then go back to wandering