## A Resource that represents a *type* of tool (e.g. Spear.tres, Turnkey.tres).
## Scene paths are stored as strings and loaded on demand, NOT as direct
## PackedScene references -- this avoids circular resource dependencies when
## a pickup scene and its ToolData end up pointing at each other.
extends Resource
class_name ToolData

@export var id: StringName = &"tool"
@export var display_name: String = "Tool"
@export_file("*.tscn") var visual_scene_path: String = ""
@export_file("*.tscn") var rigidbody_scene_path: String = ""

func get_visual_scene() -> PackedScene:
	return load(visual_scene_path) as PackedScene

func get_rigidbody_scene() -> PackedScene:
	return load(rigidbody_scene_path) as PackedScene
