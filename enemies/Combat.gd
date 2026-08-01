extends State
class_name Combat

@export var enemy : CharacterBody3D
var target : CharacterBody3D

var distance_to_target : Vector3
var distance : float

enum CombatAction {
	ATTACK,
	HEAVY_ATTACK,
	GROUND_POUND,
	RANGED,
}


var action_data = {
	CombatAction.ATTACK: {
		"weight": 30,
		"min_range": 0,
		"max_range": 2
	},
	CombatAction.HEAVY_ATTACK: {
		"weight": 30,
		"min_range": 0,
		"max_range": 2
	},
	CombatAction.GROUND_POUND: {
		"weight": 30,
		"min_range": 1,
		"max_range": 5
	},
	CombatAction.RANGED: {
		"weight": 30,
		"min_range": 4,
		"max_range": 15
	},
	
}

func _physics_process(delta: float) -> void:
	if target == null or enemy == null:
		return
		
	distance_to_target = target.global_position - enemy.global_position
	distance = distance_to_target.length()


func choose_action(distance: float) -> CombatAction:
	var valid_actions = []
	var total_weight := 0

	# Find attacks that are possible at this distance
	for action in action_data:
		var data = action_data[action]

		if distance >= data["min_range"] and distance <= data["max_range"]:
			valid_actions.append(action)
			total_weight += data["weight"]

	# No valid attacks
	if valid_actions.is_empty():
		return CombatAction.ATTACK

	# Weighted random selection
	var roll := randi_range(1, total_weight)

	for action in valid_actions:
		roll -= action_data[action]["weight"]
		if roll <= 0:
			return action

	return CombatAction.ATTACK
	
	

func perform_action():
	
	var action = choose_action(distance)

	match action:
		CombatAction.ATTACK:
			attack();
		CombatAction.HEAVY_ATTACK:
			heavy_attack()
		CombatAction.GROUND_POUND:
			ground_pound()
		CombatAction.RANGED:
			ranged()
		

func attack():
	return

func heavy_attack():
	return

func ground_pound():
	return
	
func ranged():
	return
