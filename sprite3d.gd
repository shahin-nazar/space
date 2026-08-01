extends Sprite3D

@export var girl_toggle := false
@export var parasite_toggle := false

@export var girl_text_color := Color("#37a95a")
@export var parasite_text_color := Color("#c26c76")


func _ready() -> void:
	print(parasite_toggle, girl_toggle)
	for child in get_children(true):
		print(child)
		if child is SubViewport:
			texture = child.get_texture()

			for subchild in child.get_children():
				if subchild is Label:
					print(subchild)
					if girl_toggle:
						subchild.label_settings = subchild.label_settings.duplicate() # important
						subchild.label_settings.font_color = girl_text_color
					
					if parasite_toggle:
						subchild.label_settings = subchild.label_settings.duplicate() # important
						subchild.label_settings.font_color = parasite_text_color
