extends Camera2D

var ZOOM_MIN:Vector2 = Vector2(0.15, 0.15)
const ZOOM_MAX:Vector2 = Vector2(0.75, 0.75)
const ZOOM_STEP = Vector2(0.05, 0.05)
var _zoom:Vector2 = Vector2(0.5, 0.5):
	get:
		return _zoom
	set(value):
		_zoom = clamp(value, ZOOM_MIN, ZOOM_MAX)


func _input(event: InputEvent) -> void:
	if Navigation.in_galaxy_warp == false:
		if Input.is_action_pressed("zoom_out"):
			if _zoom > ZOOM_MIN:
				_zoom -= ZOOM_STEP

		if Input.is_action_pressed("zoom_in"):
			if _zoom < ZOOM_MAX:
				_zoom += ZOOM_STEP

func _process(delta: float) -> void:
	if Navigation.in_galaxy_warp == false:
		if zoom != _zoom:
			zoom = _zoom
