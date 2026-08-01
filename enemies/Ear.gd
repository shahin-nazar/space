class_name EarComponent
extends Area3D

@export var owner_character: CharacterBody3D

var noise_source : Area3D
var heard_noise := false
var source_location : Vector3
var last_source_location : Vector3

signal target_heard(location: Vector3)

func _ready() -> void:
	monitoring = true
	monitorable = false
	
	area_entered.connect(_on_area_connected)
	area_exited.connect(_on_area_exited)

func _on_area_connected(source):
	if !source.has_method("emit_noise"):
			return
		
	source_location = source.noise_emitter_location
	
	heard_noise = true
	target_heard.emit(source_location)

func _on_area_exited(source):
	if !source.has_method("emit_noise"):
			return
			
	last_source_location = source.noise_emitter_location
	heard_noise = false
	target_heard.emit(last_source_location)
