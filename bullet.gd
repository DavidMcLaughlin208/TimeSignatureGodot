extends RigidBody2D

@export var speed = 2000
var snapshots: Array[Dictionary] = []
var queued_functions: Array[Callable] = []
var origin_point: Vector2


# Called when the node enters the scene tree for the first time.
func _ready():
	queued_functions.push_back(Callable(self, "die"))
	save_snapshot()

func save_snapshot():
	var funcs: Array[Callable] = []
	if Globals.is_pop_frame():
		for function in queued_functions:
			funcs.push_back(function)
		queued_functions = []
	var snapshot: Dictionary = {
		"position": position,
		"rotation": rotation,
		"functions_to_run": funcs
	}
	snapshots.push_back(snapshot)
	while len(snapshots) > Globals.max_rewind_frames:
		snapshots.pop_front()

func apply_snapshot(snapshot1: Dictionary, snapshot2: Dictionary, lerpValue: float):
	if len(snapshots) <= 3:
		prints("last")
	position = snapshot1["position"].lerp(snapshot2["position"], lerpValue)
	rotation = lerp(snapshot1["rotation"], snapshot2["rotation"], lerpValue)
	if Globals.is_pop_frame():
		for callable in snapshot1["functions_to_run"]:
			callable.call()

func change_state_on_hit():
	$Sprite2D.hide()
	$CollisionShape2D.disabled = true
	queued_functions.push_back(func (): 
		$Sprite2D.show()
		$CollisionShape2D.disabled = false
	)

func update_trail_position():
	$Trail.points.set(0, global_position)
	$Trail.points.set(1, origin_point)
	prints($Trail.points)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Globals.timestate == Globals.TimeState.PLAY:
		var forward_direction = Vector2(0, -1).rotated(rotation)
		var velocity = forward_direction * speed * delta * Globals.timescale
		var collision: KinematicCollision2D = move_and_collide(velocity)
		if collision:
			change_state_on_hit()
			var other_node = collision.get_collider()
			if other_node.has_method("receive_bullet"):
				other_node.receive_bullet(self)
				
		update_trail_position()
		if Globals.is_pop_frame():
			save_snapshot()
	if Globals.timestate == Globals.TimeState.REWIND:
		if len(snapshots) == 0:
			return
		
		var snapshot2 = snapshots[-2] if len(snapshots) > 1 else snapshots[-1]
		apply_snapshot(snapshots[-1], snapshot2, Globals.timescaleAccumulator)
		update_trail_position()
		if Globals.is_pop_frame():
			snapshots.pop_back()
		

func die():
	queue_free()
