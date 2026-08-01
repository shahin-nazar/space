extends Camera3D

@onready var area_3d: Area3D = $Area3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	area_3d.global_position = area_3d.global_position
