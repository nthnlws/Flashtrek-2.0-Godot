extends Camera2D


@onready var player = $".."

var ZOOM_MIN:Vector2 = Vector2(0.15, 0.15)
const ZOOM_MAX:Vector2 = Vector2(0.75, 0.75)
const ZOOM_STEP = Vector2(0.05, 0.05)
var _zoom:Vector2 = Vector2(0.5, 0.5):
	get:
		return _zoom
	set(value):
		if Utility.mainScene.in_galaxy_warp == false:
			_zoom = clamp(value, ZOOM_MIN, ZOOM_MAX)


func _input(event):
	if Utility.mainScene.in_galaxy_warp == false:
		if Input.is_action_pressed("zoom_out"):
			if _zoom > ZOOM_MIN:
				_zoom -= ZOOM_STEP

		if Input.is_action_pressed("zoom_in"):
			if _zoom < ZOOM_MAX:
				_zoom += ZOOM_STEP

func _process(delta):
	if Utility.mainScene.in_galaxy_warp == false:
		if zoom != _zoom:
			zoom = _zoom
	#if player.warping_active == true:
		#ZOOM_MIN = Vector2(0.1, 0.1)
	#elif player.warping_active == false:
		#zoom_min = Vector2(0.1,0.1)
