extends Camera2D

var zoomspeed = 4
var zoommargin = 0.1

var zoomMin = 0.35
var zoomMax = 2.0

var zoompos = Vector2()
var zoomfactor = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	zoom.x = zoom.x * zoomfactor
	zoom.y = zoom.y * zoomfactor
	
	zoom.x = clamp(zoom.x, zoomMin, zoomMax)
	zoom.y = clamp(zoom.y, zoomMin, zoomMax)

func _input(event):
	if abs(zoompos.x - get_global_mouse_position().x) > zoommargin:
		zoomfactor = 1.0
	if abs(zoompos.y - get_global_mouse_position().y) > zoommargin:
		zoomfactor = 1.0
	
	if Input.is_action_just_pressed("zoom_out"):
		zoomfactor -= 0.01
	if Input.is_action_just_pressed("zoom_in"):
		zoomfactor += 0.01
