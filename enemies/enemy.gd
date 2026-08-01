extends CharacterBody3D

@export_category("Code Nodes")
@export var body : CharacterBody3D

@export_category("Components")
@export var movement_component : EnemyMovementComponent
@export var visioncone : Area3D
@export var hurt_box_component : EnemyHurtBoxComponent
@export var ear : EarComponent
@export var healthbar : HealthComponent
@export var boid_controller : BoidController
@export var boid_obstacle_avoider : BoidObstacleAvoider
@export var ground_cast_component : GroundCastComponent
@export var enemy_death_component : EnemyDeathComponent

@export_category("State Machine Nodes")
@export var statemachine : Node
@export var followstate : State
@export var idlestate : State
@export var cautionstate : State
@export var roamingstate : State
@export var combatstate : State

@export_category("Debug Labels")
@export var statelabel : Label
@export var visionlabel : Label

@export_category("Internal Params")
var is_staggered : bool
var is_launched : bool
var was_launched : bool
var is_knocked_out : bool
var is_parried : bool
var spawn_location : Vector3



func _ready():
	get_tree().current_scene.get_node("GameSystems/DropSystem").register_enemy(self)
	
	spawn_location = body.global_position
	
	hurt_box_component.owner_character = self
	hurt_box_component.health_depleted.connect(queue_free)
	
	ear.target_heard.connect(cautionstate.set_source_location)
	
	visioncone.target_seen.connect(followstate.target_seen)
	visioncone.target_unseen.connect(followstate.target_lost)
	
	visioncone.target_unseen.connect(cautionstate.set_source_location)
	visioncone.target_seen.connect(cautionstate._on_target_seen)
	
	hurt_box_component.health_depleted.connect(enemy_death_component.die)
	

func _physics_process(delta: float) -> void:
	followstate.sees_player = visioncone.sees_player
	followstate.target = visioncone.target
	
	idlestate.heard_noise = ear.heard_noise
	idlestate.sees_player = visioncone.sees_player
	
	roamingstate.heard_noise = ear.heard_noise
	roamingstate.sees_player = visioncone.sees_player

	combatstate.target = visioncone.target

	

	# cliff detection
	ground_cast_component.apply_edge_avoidance(delta)

	# DEBUGQ
	statelabel.text = str(statemachine.current_state)
	visionlabel.text = str(visioncone.sees_player)
	
#	boid_controller.update_boids(delta)
	movement_component.update_movement(delta)
	
