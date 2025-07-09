extends ProgressBar

func set_bar_position(x: float, y: float):
	custom_minimum_size = Vector2(20.0, y)
	size = Vector2(20.0, y)
	position = Vector2(x, 0.0)
