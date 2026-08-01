extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(highlight)
	body_exited.connect(remove_highlight)


func highlight(body):
	if body.is_in_group("tools"):
		for child in body.get_children():
			if child is MeshInstance3D:
				var material = child.get_active_material(0) as StandardMaterial3D
				material.emission_enabled = true
				material.emission_energy_multiplier = 0.0
				material.emission = Color(1, 1, 0) # red
				var tween = create_tween()
				tween.tween_property(
					material,
					"emission_energy_multiplier",
					1.0,
					5.0
				)
				
				

func remove_highlight(body):
	if body.is_in_group("tools"):
		for child in body.get_children():
			if child is MeshInstance3D:
				var material = child.get_active_material(0) as StandardMaterial3D
				var tween = create_tween()
				tween.tween_property(
					material,
					"emission_energy_multiplier",
					0.0,
					.5
				)
				tween.tween_callback(func():
					material.emission_enabled = false
				)
				
