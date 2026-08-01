extends State
class_name Idle

@export var enemy : CharacterBody3D

var sees_player : bool
var heard_noise : bool

func enter():
	print("ENTER IDLE")
	
func physics_update(_delta: float):
	enemy.velocity = Vector3.ZERO
	if sees_player:
		transitioned.emit(self, "follow")
	elif heard_noise:
		transitioned.emit(self, "caution")
