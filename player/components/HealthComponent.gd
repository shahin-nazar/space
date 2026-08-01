class_name HealthComponent extends ProgressBar

@export var body: CharacterBody3D

signal healthbar_changed(value)
signal healthbar_depleted

func apply_damage(amount: int):
	value -= amount
	emit_signal("healthbar_changed", value)

	if value <= 0:
		emit_signal("healthbar_depleted")
