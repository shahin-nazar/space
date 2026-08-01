extends CSGCombiner3D

@export var shader_material: ShaderMaterial

func _ready():
	# Apply material to self if it's a primitive
	if self is CSGPrimitive3D:
		self.material = shader_material
	
	# Apply material recursively to children
	_apply_material_recursive(self)

func _apply_material_recursive(node: Node):
	for child in node.get_children():
		# MeshInstance3D uses material_override
		if child is MeshInstance3D:
			child.material_override = shader_material
		# Only apply to CSG primitives (not combiners)
		elif child is CSGPrimitive3D:
			child.material = shader_material
		
		# Recurse into children
		_apply_material_recursive(child)
