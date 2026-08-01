extends Node
class_name ToolAttacherComponent

@export var toolraycast: ShapeCast3D
@export var toolslot: Node3D
@export var lerpspeed := 1.0

var equipped_tool_data: ToolData
var toolslot_filled: bool:
	get: return equipped_tool_data != null

func attach_tool() -> void:
	if toolslot_filled or not toolraycast.is_colliding():
		return

	var pickup: ToolPickup = null
	for i in range(toolraycast.get_collision_count()):
		var collider := toolraycast.get_collider(i)
		if collider is ToolPickup and collider.is_in_group("tools"):
			pickup = collider
			break

	if pickup == null or pickup.tool_data == null:
		return

	pickup.global_transform.basis = toolslot.global_transform.basis
	_swap_to_visual(pickup, pickup.tool_data)

func drop_tool() -> void:
	if not toolslot_filled:
		return

	var current_visual := toolslot.get_child(0) if toolslot.get_child_count() > 0 else null
	var rb := _swap_to_rigidbody(current_visual, equipped_tool_data)
	if rb == null:
		return
	rb.global_transform = toolslot.global_transform

func use_tool() -> void:
	if not toolslot_filled:
		return
	var current_tool := toolslot.get_child(0) if toolslot.get_child_count() > 0 else null
	if current_tool and current_tool.has_method("use"):
		current_tool.use()

func _swap_to_visual(pickup: ToolPickup, data: ToolData) -> void:
	print("equipping: ", data.id)
	equipped_tool_data = data

	pickup.queue_free()

	var visual = data.get_visual_scene().instantiate()
	toolslot.add_child(visual)

func _swap_to_rigidbody(visual_tool: Node, data: ToolData) -> RigidBody3D:
	if visual_tool == null or data == null:
		return null

	var start := (visual_tool as Node3D).global_transform
	visual_tool.queue_free()

	var rigidbody := data.get_rigidbody_scene().instantiate() as RigidBody3D
	get_tree().current_scene.add_child(rigidbody)
	rigidbody.global_transform = start

	if rigidbody is ToolPickup:
		(rigidbody as ToolPickup).tool_data = data

	equipped_tool_data = null
	return rigidbody
