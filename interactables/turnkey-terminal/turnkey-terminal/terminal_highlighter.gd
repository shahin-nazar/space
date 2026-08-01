extends Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area_entered.connect(highlight)
	area_exited.connect(remove_highlight)
	



func highlight(area):
	if area.is_in_group("tools"):
		for child in get_children():
			if child is MeshInstance3D:
				var material = child.get_active_material(0) as ShaderMaterial

				var tween = create_tween()
				tween.tween_method(
					func(value):
						material.set_shader_parameter("distortionVertex", value),
					0.3,
					0.0,
					1.0
				)

				var emissiontween = create_tween()
				emissiontween.tween_method(
					func(value):
						material.set_shader_parameter("ems", value),
					0.0,
					2.0,
					1.0
				)
				

func remove_highlight(area):
	if area.is_in_group("tools"):
		for child in get_children():
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
				
