extends CharacterBody2D

var snapshots: Array[Dictionary] = []
@onready var bullet_scene = preload("res://bullet.tscn");
var queued_functions: Array[Callable] = []
enum EnemyState {IDLE, SEARCHING, COMBAT, DEAD}
var enemy_state = EnemyState.COMBAT
var fire_cooldown = Globals.fps
var current_fire_cooldown = 0
var movement_speed: int = 150;
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_movement_target(movement_target: Vector2):
	navigation_agent.target_position = movement_target

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	# Now that the navigation map is no longer empty, set the movement target.
	var player: CharacterBody2D = get_tree().get_nodes_in_group("player")[0]
	set_movement_target(player.global_position)
	
	
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
		set_movement_target(player.global_position)
		look_at(player.global_position)

		var current_agent_position: Vector2 = global_position
		var next_path_position: Vector2 = navigation_agent.get_next_path_position()

		velocity = current_agent_position.direction_to(next_path_position) * movement_speed * Globals.timescale
		move_and_slide()
		var space_state = get_world_2d().direct_space_state
		# use global coordinates, not local to node
		var query = PhysicsRayQueryParameters2D.create($Gun/Barrel.global_position, player.global_position)
		var result = space_state.intersect_ray(query)
		if result and result.collider.is_in_group("player"):
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
