class_name PlayerHurtBoxComponent
extends Area3D


@export var health_component: ProgressBar
var owner_character: Node = null
@export var curve : Curve


@export_category("Health Params")
@export var health : float
@export var max_health : float = 100

signal damaged(amount: float, source: Node)
signal health_depleted

signal healed(amount: float, source: Node)

func _ready() -> void:
	monitoring = true
	monitorable = true

	health = max_health


func take_hit(amount: float, source: Node) -> void:
	if source == owner_character:
		return
	
	var t = clamp(health/max_health, 0.0, 1.0)
	var multiplier = curve.sample(t)
	var new_amount = amount * multiplier
	
	health -= new_amount
	health_component.value = health
	#emit_signal("damaged", amount, source)
	damaged.emit(new_amount, source)

	print(owner_character, " took ", new_amount, " damage")
	print("remaining health: ", health)

	if health <= 0:
		die(source)
	
	if health >= 100:
		health = 100

func heal(amount: float, source: Node) -> void:
	if health >= max_health:
		amount = 0
		
	if source == owner_character:
		return

	
	health += amount
	health_component.value = health
	#emit_signal("damaged", amount, source)
	healed.emit(amount, source)

	print(owner_character, " healed for ", heal, " points")
	print("remaining health: ", health)

	




func die(_source: Node) -> void:
	print(owner_character, " died")
	health_depleted.emit()
	
