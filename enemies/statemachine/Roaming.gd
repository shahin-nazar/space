extends State
class_name Roaming

@export var enemy : CharacterBody3D

var sees_player : bool
var heard_noise : bool

func enter():
	print("ENTER ROAMING")
	
func physics_update(_delta: float):
	if sees_player:
		transitioned.emit(self, "follow")
	elif heard_noise:
		transitioned.emit(self, "caution")
