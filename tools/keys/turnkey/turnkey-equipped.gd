extends Area3D

var tool_primed := false
@export var key_type : KeyTypeData

func _ready() -> void:
	monitoring = true
	monitorable = true
	area_entered.connect(on_area_entered)
	area_exited.connect(on_area_exited)

func _process(_delta: float) -> void:
	print(tool_primed)

func on_area_entered(area):
	print("1. turnkey area entered by:", area)
	if area.has_method("unlock"):
		print("1.1 area has method unlock:", area)
		tool_primed = true


func on_area_exited(area):
	print("2. turnkey area exited by:", area)
	if area.has_method("unlock"):
		print("2.2 turneky exited and area is:", area)
		tool_primed = false


func use():
	print("3. used")
	if tool_primed:
		for area in get_overlapping_areas():
			if area.has_method("unlock"):
				print("3.3 area with unlock is:", area)
				#print(area.get_script())
				#print(area.get_class())
				area.unlock()
	if !tool_primed:
		return
