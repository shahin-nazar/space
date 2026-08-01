extends State
class_name Caution

@export_category("Core Nodes")
@export var source_forget_timer : Timer
@export var enemy : CharacterBody3D

@export_category("External Params")
var source_location : Vector3
var target_seen : bool

@export_category("Internal Params")
@export var forget_time := 10.0

const TURN_SPEED = 2
const SPEED = 5


func _ready():
	source_forget_timer.timeout.connect(_on_forget_timeout)
	
func enter():
	target_seen = false
	
	source_forget_timer.wait_time = forget_time
	source_forget_timer.start()
	print("ENTER CAUTION")

func physics_update(delta: float) -> void:
	move_to_source(delta)
	
	if target_seen:
		transitioned.emit(self, "follow")

func set_source_location(location: Vector3):
	source_location = location

func move_to_source(_delta):
	enemy.look_at(source_location)
	var direction = source_location - enemy.global_position
	direction.y = 0
	var distance = direction.length()
	direction = direction.normalized()
	
	enemy.velocity.x = direction.x * SPEED
	enemy.velocity.z = direction.z * SPEED
	
	if distance < 1.0:
		enemy.velocity.x = 0.0
		enemy.velocity.z = 0.0

func _on_forget_timeout():
	transitioned.emit(self, "idle")

func _on_target_seen(_target): # why do I use target here? check later!
	transitioned.emit(self, "follow")


func exit():
	print("EXIT CAUTION")
	source_forget_timer.stop()
