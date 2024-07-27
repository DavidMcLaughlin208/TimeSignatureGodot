extends Node
signal timestate_updated
signal timescale_updated

enum TimeState {PLAY, PAUSED, REWIND}
var timescale = 1.0
var timestate = TimeState.PLAY
var timescaleAccumulator = 0
var pop_frame = false
var rewind_capacity: float = 5
var fps = 120
var max_rewind_frames: int = floor(rewind_capacity * fps)
var queued_timestate = null
var queued_timescale = null



# Called when the node enters the scene tree for the first time.
func _ready():
	process_priority = 0

func is_pop_frame():
	return pop_frame


func set_time(new_timestate: TimeState, new_timescale: float):
	queued_timestate = new_timestate
	queued_timescale = new_timescale

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print(timescaleAccumulator)
	if timescaleAccumulator >= 1.0:
		timescaleAccumulator = 0
		
	pop_frame = false
	timescaleAccumulator += timescale
	if timescaleAccumulator >= 1.0:
		pop_frame = true
	if (pop_frame or timestate == TimeState.PAUSED) and queued_timescale or queued_timestate:
		if queued_timescale != null:
			timescale = queued_timescale
			queued_timescale = null
			timescale_updated.emit()
			
		if queued_timestate != null:
			timestate = queued_timestate
			queued_timestate = null
			timestate_updated.emit()
		
