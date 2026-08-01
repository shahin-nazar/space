extends State
class_name Wander

# all state nodes have an enter(), update(), physics_update() and exit()
# emit signal when it wants to change state

@export var opponent : CharacterBody3D
@export var move_speed := 3.0

var move_direction : Vector3
var wander_time : float
var roam_range := 5.0

func randomize_wander():
	move_direction = Vector3(randf_range(-roam_range, roam_range),0,randf_range(-roam_range, roam_range),)
	wander_time = randf_range(1, 3)

func enter():
	randomize_wander()
	print('randomized wander')

func update(_delta: float):
	if wander_time > 0:
		wander_time -= _delta

	else:
		randomize_wander()

func physics_update(_delta: float):
	if opponent:
		opponent.velocity = move_direction * move_speed
		#gotta call move_and_slide in the parent characterbody3d for this to work
		
		if move_direction.length() > 0.1:
			var target_pos = opponent.global_transform.origin - move_direction
			opponent.look_at(target_pos, Vector3.UP)
