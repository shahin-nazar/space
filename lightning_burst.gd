extends Node3D

@export var target_mesh: MeshInstance3D
@export var area_size := Vector2(50.0, 50.0)

func _ready():
	randomize()
	start_loop()

func start_loop():
	while true:
		var delay_time = randf_range(4.0, 10.0)
		var burst_time = randf_range(0.1, 0.4)

		spawn_burst(burst_time)

		await get_tree().create_timer(delay_time).timeout

func spawn_burst(burst_time: float):
	var x = randf_range(-area_size.x * 0.5, area_size.x * 0.5)
	var z = randf_range(-area_size.y * 0.5, area_size.y * 0.5)

	target_mesh.position = Vector3(x, target_mesh.position.y, z)
	target_mesh.visible = true

	await get_tree().create_timer(burst_time).timeout
	target_mesh.visible = false