extends RigidBody3D
class_name Player

@export var input_component : InputComponent
@export var movement_component : MovementComponent
@export var tool_attacher_component : ToolAttacherComponent
@export var demand_interact_component : DemandInteractComponent

@export var left_target : Marker3D
@export var right_target : Marker3D
@export var left_leg_target : Marker3D
@export var right_leg_target : Marker3D

var targets := []
var rest_positions := {}
var rest_rotations := {}
var smoothed_local_vel := Vector3.ZERO
var smoothed_local_ang_vel := Vector3.ZERO


func _ready():
	input_component.restart.connect(restart_game)
	
	input_component.y_pressed.connect(tool_attacher_component.attach_tool)
	input_component.b_pressed.connect(tool_attacher_component.drop_tool)
	input_component.x_pressed.connect(tool_attacher_component.use_tool)
	
	input_component.a_pressed.connect(demand_interact_component.demand_interact)

	
	#IK
	targets = [
		left_target,
		right_target,
		left_leg_target,
		right_leg_target
	]

	for target in targets:
		rest_positions[target] = target.position
		rest_rotations[target] = target.rotation


func _physics_process(delta: float) -> void:
	

	if input_component.running:
		movement_component.linear_force = movement_component.max_speed_linear
	else: 
		movement_component.linear_force = movement_component.min_speed_linear


	#print(rad_to_deg(rotation.z))
	var local_vel = global_basis.inverse() * linear_velocity
	var local_ang_vel = global_basis.inverse() * angular_velocity
	smoothed_local_vel = smoothed_local_vel.lerp(local_vel, 10.0 * delta)
	smoothed_local_ang_vel = smoothed_local_ang_vel.lerp(local_ang_vel, 10.0 * delta)
	
	# IK velocity adjustments

	

	for target in targets:
		# L Stick forwardbackwardsideways
		target.position = rest_positions[target] + smoothed_local_vel * 0.4
		
		# rolling throws arms sideways RT LT
		target.position.x -= smoothed_local_ang_vel.z * 0.3

		# pitching throws arms up/down
		target.position.y -= smoothed_local_ang_vel.x * 0.3

		# y axis  throws arms outward
		target.position.x -= smoothed_local_ang_vel.y * 0.3


func restart_game():
	get_tree().reload_current_scene()
