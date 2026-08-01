extends Area3D

@export var doors : Array[Node3D] = []


func turnkey_approve():
	pass

func unlock():
	print("terminal requesting unlock")
	for door in doors:
		if door != null and door.has_method("open"):
			door.open()

