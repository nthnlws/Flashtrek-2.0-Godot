extends Control
class_name PolygonMouseDetector

signal pressed
signal released

@onready var polygon: Polygon2D = $Polygon2D

func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, polygon.polygon)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			get_viewport().set_input_as_handled()
			pressed.emit()
		# Release returns to hover state unless disabled
		elif event.is_action_released("left_click"):
			get_viewport().set_input_as_handled()
			released.emit()
