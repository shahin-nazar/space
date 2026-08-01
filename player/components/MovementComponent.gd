extends Node
class_name MovementComponent

@export var body : RigidBody3D

@export var joypad_sensitivity = 0.15
@export var max_speed_turn := 2.0
@export var max_speed_linear := 15.0
@export var min_speed_linear := 15.0

@export var turn_force : float = 10
@export var linear_force : float = 15
@export var central_force: float = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	move_ship()
	move_ship_pc()


func move_ship():
	var turn_strength = turn_force
	var turn_sideways_strength = turn_force / 2
	
	var rightstick_input_dir = Input.get_vector("Rleft","Rright", "Rup", "Rdown")
	var trigger_input_dir = Input.get_axis("RT", "LT")
	var leftstick_input_dir = Input.get_vector("Lleft", "Lright", "Lup", "Ldown")
	var button_input_dir = Input.get_axis("RB", "LB")

	# local axes
	var local_y := body.basis.y #yaw
	var local_x := body.basis.x #pitch
	var local_z := body.basis.z
	
	body.linear_velocity = body.linear_velocity.limit_length(max_speed_linear)
	body.angular_velocity = body.angular_velocity.limit_length(max_speed_turn)
	
	# rotate
	if body.angular_velocity.length() < max_speed_turn:
		# yaw
		body.apply_torque(local_y * -rightstick_input_dir.x * turn_strength)
		# pitch
		body.apply_torque(local_x * -rightstick_input_dir.y * turn_strength)
		# sideways rotation around z axis
		body.apply_torque(local_z * button_input_dir * turn_sideways_strength)
		
	# up and down
	if abs(body.linear_velocity.length()) < max_speed_linear and abs(trigger_input_dir) > 0.01:
		body.apply_central_force(local_y * -trigger_input_dir * central_force)
		
	body.apply_central_force((
		body.basis.x * leftstick_input_dir.x + body.basis.z * leftstick_input_dir.y
		) * linear_force)
		
	#if Input.is_action_just_released("RT") and Input.is_action_just_released("A"):
	#	player.rotate_y(PI)


func move_ship_pc():
	var turn_strength = turn_force
	var turn_sideways_strength = turn_force / 2
	
	var arrow_input_dir = Input.get_vector("arrowleft","arrowright", "arrowup", "arrowdown")
	var wasd_input_dir = Input.get_vector("a","d", "w", "s")
	var trigger_input_dir = Input.get_axis("z", "x")
	var button_input_dir = Input.get_axis("e", "q")

	# local axes
	var local_y := body.basis.y #yaw
	var local_x := body.basis.x #pitch
	var local_z := body.basis.z
	
	body.linear_velocity = body.linear_velocity.limit_length(max_speed_linear)
	body.angular_velocity = body.angular_velocity.limit_length(max_speed_turn)
	
	# rotate
	if body.angular_velocity.length() < max_speed_turn:
		# yaw
		body.apply_torque(local_y * -arrow_input_dir.x * turn_strength)
		# pitch
		body.apply_torque(local_x * -arrow_input_dir.y * turn_strength)
		# sideways rotation around z axis
		body.apply_torque(local_z * button_input_dir * turn_sideways_strength)
		
	# up and down
	if abs(body.linear_velocity.length()) < max_speed_linear and abs(trigger_input_dir) > 0.01:
		body.apply_central_force(local_y * -trigger_input_dir * central_force)
		
	body.apply_central_force((
		body.basis.x * wasd_input_dir.x + body.basis.z * wasd_input_dir.y
		) * linear_force)
		
	#if Input.is_action_just_released("RT") and Input.is_action_just_released("A"):
	#	player.rotate_y(PI)
