extends CharacterBody2D

@export var speed = 400 # How fast the player will move (pixels/sec).

var snapshots: Array[Dictionary] = []
@onready var bullet_scene = preload("res://bullet.tscn");
var queued_functions: Array[Callable] = []
enum EnemyState {IDLE, SEARCHING, COMBAT, DEAD}
var enemy_state = EnemyState.COMBAT
var fire_cooldown = Globals.fps
var current_fire_cooldown = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func save_snapshot():
	var funcs: Array[Callable] = []
	if Globals.is_pop_frame():
		for function in queued_functions:
			funcs.push_back(function)
		queued_functions = []
	var snapshot: Dictionary = {
		"velocity": velocity,
		"position": position,
		"rotation": rotation,
		"current_fire_cooldown": current_fire_cooldown,
		"functions_to_run": funcs
	}
	snapshots.push_back(snapshot)
	while len(snapshots) > Globals.max_rewind_frames:
		snapshots.pop_front()

func apply_snapshot(snapshot1: Dictionary, snapshot2: Dictionary, lerpValue: float):
	velocity = snapshot1["velocity"].lerp(snapshot2["velocity"], lerpValue)
	position = snapshot1["position"].lerp(snapshot2["position"], lerpValue)
	rotation = lerp(snapshot1["rotation"], snapshot2["rotation"], lerpValue)
	current_fire_cooldown = snapshot1["current_fire_cooldown"]
	if Globals.is_pop_frame():
		for callable in snapshot1["functions_to_run"]:
			callable.call()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Globals.timestate == Globals.TimeState.PLAY:
		var player: CharacterBody2D = get_tree().get_nodes_in_group("player")[0]
		look_at(player.global_position)
		move_and_slide()
		if current_fire_cooldown >= fire_cooldown:
			fire_bullet()
		
		if Globals.is_pop_frame():
			save_snapshot()
			if current_fire_cooldown < fire_cooldown:
				current_fire_cooldown += 1
	elif Globals.timestate == Globals.TimeState.REWIND:
		if len(snapshots) == 0:
			return
		
		var snapshot1 = snapshots[-1]
		var snapshot2 = snapshots[-2] if len(snapshots) > 1 else snapshots[-1]
		apply_snapshot(snapshot1, snapshot2, Globals.timescaleAccumulator)
		if Globals.is_pop_frame():
			snapshots.pop_back()

func receive_bullet(bullet: RigidBody2D):
	velocity += (global_position - bullet.global_position).normalized() * 300
	var current_state = enemy_state
	enemy_state = EnemyState.DEAD
	queued_functions.push_back(Callable(func (): enemy_state = current_state))


func fire_bullet():
	var bullet_instance = bullet_scene.instantiate()
	bullet_instance.position = get_node("Gun/Barrel").global_position
	bullet_instance.rotation = get_node("Gun/Barrel").global_rotation
	get_node("/root/Main").add_child(bullet_instance)
	current_fire_cooldown = 0
	bullet_instance.origin_point = get_node("Gun/Barrel").global_position
