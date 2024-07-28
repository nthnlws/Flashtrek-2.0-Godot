extends Camera2D

var zoom_min = Vector2(0.3000001, 0.4000001)
var zoom_max = Vector2(1.0000001, 1.0000001)
var zoom_speed = Vector2(0.15000001, 0.15000001)

func _input(event):
	if Input.is_action_pressed("zoom_out"):
		if zoom > zoom_min:
			zoom -= zoom_speed

	if Input.is_action_pressed("zoom_in"):
		if zoom < zoom_max:
			zoom += zoom_speed
