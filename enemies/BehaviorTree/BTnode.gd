extends RefCounted
class_name BTNode

# this is a "composite": itis basically an OR node that succeeds if any child succeeds.

enum Status {SUCCESS, FAILURE, RUNNING}

func tick(actor: Node, blackboard: Dictionary) -> Status:
	return Status.FAILURE # overridden by subclass

# blackboard should be seen as sticky nodes the tree passes around e.g. player position, last seen, so nodes can leave info to one another
