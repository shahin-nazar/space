extends Area3D
@onready var player: RigidBody3D = $"../Player"

var slow = false

func in_slow(body):
	if body == player:
		slow = true

func exit_slow(body):
	if body == player:
		slow = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if slow:
		player.max_speed_turn = 0.5
		player.max_speed_linear = 1.5
		player.turn_force = 1
		player.linear_force = 1
		player.central_force = 1
		print("enter!")
	else:
		player.max_speed_turn = 2
		player.max_speed_linear = 5
		player.turn_force = 3
		player.linear_force = 5
		player.central_force = 2
		print("exit!")
