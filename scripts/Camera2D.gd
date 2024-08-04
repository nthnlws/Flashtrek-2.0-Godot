extends Camera2D

@onready var player = $".."

var zoom_min:Vector2
var zoom_max:Vector2 = Vector2(1.0, 1.0)
var zoom_speed = Vector2(0.10, 0.10)


func _input(event):
	if Input.is_action_pressed("zoom_out"):
		if zoom > zoom_min:
			zoom -= zoom_speed

	if Input.is_action_pressed("zoom_in"):
		if zoom < zoom_max:
			zoom += zoom_speed

func _process(delta):
	if player.warping_active == true:
		zoom_min = Vector2(0.3,0.3)
	elif player.warping_active == false:
		zoom_min = Vector2(0.4,0.4)
	
	if zoom < zoom_min:
		zoom = zoom_min

	if zoom > zoom_max:
		zoom = zoom_max
