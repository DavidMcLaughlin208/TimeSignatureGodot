extends CharacterBody2D

@export var speed = 400 # How fast the player will move (pixels/sec).
var screen_size # Size of the game window.

var snapshots: Array[Dictionary] = []
@onready var bullet_scene = preload("res://bullet.tscn");
enum PlayerState {ALIVE, DEAD}
var player_state = PlayerState.ALIVE
var queued_functions: Array[Callable] = []



# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size


func is_any_actions_just_pressed(actions):
	for action in actions:
		if Input.is_action_just_pressed(action):
			return true
	
	return false
	
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
		"functions_to_run": funcs
	}
	snapshots.push_back(snapshot)
	while len(snapshots) > Globals.max_rewind_frames:
		snapshots.pop_front()

func apply_snapshot(snapshot1: Dictionary, snapshot2: Dictionary, lerpValue: float):
	velocity = snapshot1["velocity"].lerp(snapshot2["velocity"], lerpValue)
	position = snapshot1["position"].lerp(snapshot2["position"], lerpValue)
	rotation = lerp(snapshot1["rotation"], snapshot2["rotation"], lerpValue)
	if Globals.is_pop_frame():
		for callable in snapshot1["functions_to_run"]:
			callable.call()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Globals.timestate == Globals.TimeState.PLAY:
		if Input.is_action_just_pressed("pause"):
			Globals.set_time(Globals.TimeState.PAUSED, 0.0)
			return
		elif Input.is_action_just_pressed("toggle_slow_motion"):
			if Globals.timescale == 1.0:
				Globals.set_time(Globals.TimeState.PLAY, 0.2)
			else:
				Globals.set_time(Globals.TimeState.PLAY, 1.0)
			return
		elif Input.is_action_just_pressed("rewind"):
			Globals.set_time(Globals.TimeState.REWIND, 0.2)
			return
			
		if player_state == PlayerState.ALIVE:
			var vel = Vector2.ZERO # The player's movement vector.
			if Input.is_action_pressed("move_right"):
				vel.x += 1
			if Input.is_action_pressed("move_left"):
				vel.x -= 1
			if Input.is_action_pressed("move_down"):
				vel.y += 1
			if Input.is_action_pressed("move_up"):
				vel.y -= 1


			velocity = vel.normalized() * speed * Globals.timescale
			move_and_slide()
			look_at(get_global_mouse_position())
			if Input.is_action_just_pressed("click"):
				fire_bullet()
			
		if Globals.is_pop_frame():
			save_snapshot()
		
		
	elif Globals.timestate == Globals.TimeState.PAUSED:
		if is_any_actions_just_pressed(["move_left", "move_right", "move_down", "move_up", "pause", "click"]):
			Globals.set_time(Globals.TimeState.PLAY, 1.0)
			if Input.is_action_just_pressed("click"):
				fire_bullet()
		elif Input.is_action_just_pressed("rewind"):
			Globals.set_time(Globals.TimeState.REWIND, 0.2)
	elif Globals.timestate == Globals.TimeState.REWIND:
		if Input.is_action_just_released("rewind"):
			Globals.set_time(Globals.TimeState.PAUSED, 1.0)
			return
			
		if len(snapshots) == 0:
			return
		
		var snapshot1 = snapshots[-1]
		var snapshot2 = snapshots[-2] if len(snapshots) > 1 else snapshots[-1]
		apply_snapshot(snapshot1, snapshot2, Globals.timescaleAccumulator)
		if Globals.is_pop_frame():
			snapshots.pop_back()
		
func receive_bullet(bullet: RigidBody2D):
	#player_state = PlayerState.DEAD
	#queued_functions.push_back(Callable(func (): 
		#player_state = PlayerState.ALIVE
	#))
	velocity += bullet.global_position - global_position * 10
	
	
	
func fire_bullet():
	var bullet_instance = bullet_scene.instantiate()
	bullet_instance.position = get_node("Gun/Barrel").global_position
	bullet_instance.rotation = get_node("Gun/Barrel").global_rotation
	get_node("/root/Main").add_child(bullet_instance)
	
	bullet_instance.origin_point = get_node("Gun/Barrel").global_position
	#bullet_instance.save_snapshot()
