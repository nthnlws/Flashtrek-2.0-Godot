extends Node2D

@onready var color_rect: ColorRect = $ColorRect

const VALID_COLOR = Color("lightgreen")
const INVALID_COLOR = Color("crimson")

func set_validity_color(is_valid: bool):
	if color_rect:
		if is_valid:
			color_rect.color = VALID_COLOR
		else:
			color_rect.color = INVALID_COLOR
