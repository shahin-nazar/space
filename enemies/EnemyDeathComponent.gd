extends Node
class_name EnemyDeathComponent

signal died(pos: Vector3)

func die():
	died.emit(get_parent().global_position)
	queue_free()
