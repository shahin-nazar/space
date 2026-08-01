extends Area3D
class_name TriggerComponent

var in_trigger = false
signal trigger_state(state: bool)

func _ready():
	body_entered.connect(enter_trigger)
	body_exited.connect(exit_trigger)

func enter_trigger(body):
	if body.is_in_group("player"):
		in_trigger = true
		trigger_state.emit(true)

func exit_trigger(body):
	if body.is_in_group("player"):
		in_trigger = false
		trigger_state.emit(false)
		
