extends StaticBody3D

#@onready var mesh := $MeshInstance3D
#@onready var collision := $CollisionShape3D

func open():
	visible = false
	set_collision_layer_value(1, false)
