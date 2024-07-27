extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.connect("timestate_updated", _on_timestate_updated, 0)
	Globals.connect("timescale_updated", _on_timescale_updated, 0)
	$TimeStateLabel.text = str(Globals.TimeState.keys()[Globals.timestate])
	$TimeScaleLabel.text = str(Globals.timescale)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_timestate_updated():
	$TimeStateLabel.text = str(Globals.TimeState.keys()[Globals.timestate])

func _on_timescale_updated():
	$TimeScaleLabel.text = str(Globals.timescale)
