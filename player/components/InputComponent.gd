extends Node
class_name InputComponent

signal run_pressed
signal run_released

signal y_pressed
signal b_pressed
signal a_pressed
signal x_pressed
signal restart

var running := false

func _physics_process(_delta: float) -> void:
	running = Input.is_action_pressed("run")

	if Input.is_action_just_pressed("Y"):
		y_pressed.emit()
	if Input.is_action_just_pressed("B"):
		b_pressed.emit()
	if Input.is_action_just_pressed("A"):
		a_pressed.emit()
	if Input.is_action_just_pressed("X"):
		x_pressed.emit()
	if Input.is_action_just_pressed("restart"):
		restart.emit()
	
