extends BTNode
class_name BTComposite

var children : Array[BTNode] = []

func add_behavior(node: BTNode) -> void:
	children.append(node)

