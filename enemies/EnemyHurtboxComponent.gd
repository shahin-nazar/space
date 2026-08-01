class_name EnemyHurtBoxComponent
extends Area3D

@export var health_component: ProgressBar

var owner_character: Node = null

@export var health : float
@export var max_health : float = 30

signal damaged(amount: float, source: Node)
signal health_depleted

func _ready() -> void:
	monitoring = true
	monitorable = true

	health = max_health


func take_hit(amount: float, source: Node) -> void:
	if source == owner_character:
		return

	health -= amount
	health_component.value = health
	#emit_signal("damaged", amount, source)
	damaged.emit(amount, source)

	#print(owner_character, " took ", amount, " damage")
	#print("remaining health: ", health)

	if health <= 0:
		defeated(source)


func defeated(_source: Node) -> void:
	print(owner_character, " died")
	health_depleted.emit()
	
