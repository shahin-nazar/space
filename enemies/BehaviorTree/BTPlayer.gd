extends Node
class_name BTPlayer

@export var actor : Node #parent

var root : BTNode
var blackboard : Dictionary = {}

func _ready() -> void:
	root = _build_tree()

func _physics_process(delta: float) -> void:
	root.tick(actor, blackboard)

func _build_tree() -> BTNode:
	var root_selector := BTSelector.new()

	# branch 1: if can see the player, chase
	var chase_sequence := BTSequence.new()
	chase_sequence.add_behavior(BTConditionCanSeePlayer.new())
	chase_sequence.add_behavior(BTActionChase.new())


	# branch 2: otherwise just roam round
	var roam := BTActionRoam.new()

	root_selector.add_behavior(chase_sequence)
	root_selector.add_behavior(roam)

	return root_selector
