extends ShapeCast3D
class_name DemandInteractComponent

func demand_interact():
	if is_colliding():
		for i in get_collision_count():
			var collider = get_collider(i)
			if collider.has_method("interact"):
				collider.interact
