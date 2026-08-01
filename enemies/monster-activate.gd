extends Area3D

signal activate_monster

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	body_entered.connect(activate_monster)


func awake():
	activate_monster.emit()
