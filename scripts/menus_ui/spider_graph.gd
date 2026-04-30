@tool
extends Control
class_name SpiderGraph

@export var axes: Array[String] = ["SPEED", "ARMOR", "SHIELDS", "DAMAGE", "RANGE", "AGILITY"]:
	set(value):
		axes = value
		axis_label_offsets.resize(axes.size()) # Keep offsets array in sync with axes
		_rebuild_values()

@export_group("Appearance")
@export var graph_color: Color = Color(0.4, 0.6, 1.0, 0.8):
	set(value): graph_color = value; queue_redraw()
@export var fill_color: Color = Color(0.4, 0.6, 1.0, 0.15):
	set(value): fill_color = value; queue_redraw()
@export var grid_color: Color = Color(1.0, 1.0, 1.0, 0.08):
	set(value): grid_color = value; queue_redraw()
@export var label_color: Color = Color(1.0, 1.0, 1.0, 0.55):
	set(value): label_color = value; queue_redraw()
@export var grid_rings: int = 6:
	set(value): grid_rings = value; queue_redraw()
@export var label_font_size: int = 11:
	set(value): label_font_size = value; queue_redraw()
@export var label_offset: float = 18.0:
	set(value): label_offset = value; queue_redraw()
	
# Added manual Vector2 offsets per axis
@export var axis_label_offsets: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]:
	set(value):
		axis_label_offsets = value
		queue_redraw()

@export_group("Preview Values")
@export var preview_values: Array[float] = [0.75, 1.0, 0.8, 0.2, 0.6, 0.5]:
	set(value):
		preview_values = value
		if Engine.is_editor_hint():
			_apply_preview_values()
			queue_redraw()

var _values: Dictionary = {}


func _ready() -> void:
	_rebuild_values()
	if Engine.is_editor_hint():
		_apply_preview_values()


func _apply_preview_values() -> void:
	for i in min(preview_values.size(), axes.size()):
		_values[axes[i]] = clampf(preview_values[i], 0.0, 1.0)


func _rebuild_values() -> void:
	var new_values: Dictionary = {}
	for axis in axes:
		new_values[axis] = _values.get(axis, 0.0)
	_values = new_values
	if Engine.is_editor_hint():
		_apply_preview_values()
	queue_redraw()


# --- Public API ---

func set_value(axis: String, value: float) -> void:
	if Engine.is_editor_hint():
		return
	if not axis in _values:
		push_warning("SpiderGraph: axis '%s' not found." % axis)
		return
	_values[axis] = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_all_values(value_map: Dictionary[String, float]) -> void:
	if Engine.is_editor_hint():
		return
	for key:String in value_map:
		if key in _values:
			_values[key] = clampf(value_map[key], 0.0, 1.0)
		else: printerr('No key: %s found in spider graph axes' % key)
	queue_redraw()


func get_value(axis: String) -> float:
	return _values.get(axis, 0.0)


# --- Rendering ---

func _draw() -> void:
	var count: int = axes.size()
	if count < 3:
		return

	var center: Vector2 = size / 2.0
	var radius: float = min(size.x, size.y) / 2.0 - label_offset - label_font_size

	for ring in range(1, grid_rings + 1):
		var ring_radius: float = radius * (float(ring) / grid_rings)
		var ring_points: PackedVector2Array
		for i in count:
			ring_points.append(center + _axis_vector(i, count, ring_radius))
		draw_polyline(_close_loop(ring_points), grid_color, 0.8)

	for i in count:
		var tip: Vector2 = center + _axis_vector(i, count, radius)
		draw_line(center, tip, grid_color, 0.8)

	var data_points: PackedVector2Array
	for i in count:
		var val: float = _values.get(axes[i], 0.0)
		data_points.append(center + _axis_vector(i, count, radius * val))
	draw_colored_polygon(_close_loop(data_points), fill_color)
	draw_polyline(_close_loop(data_points), graph_color, 1.5)

	for pt in data_points:
		draw_circle(pt, 3.0, graph_color)

	var font: Font = ThemeDB.fallback_font
	for i in count:
		var tip: Vector2 = center + _axis_vector(i, count, radius + label_offset)
		
		# Grab the manual offset for this specific axis (fallback to Vector2.ZERO if array is out of sync)
		var custom_offset: Vector2 = Vector2.ZERO
		if i < axis_label_offsets.size():
			custom_offset = axis_label_offsets[i]
			
		var label: String = axes[i]
		var label_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size)
		
		# Apply custom offset, center the text on X/Y, and adjust for font ascent (baseline fix)
		var text_pos: Vector2 = tip + custom_offset - (label_size / 2.0)
		text_pos.y += font.get_ascent(label_font_size) 
		
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_font_size, label_color)


func _axis_vector(index: int, count: int, length: float) -> Vector2:
	var angle: float = (TAU * index / count) - (PI / 2.0)
	return Vector2(cos(angle), sin(angle)) * length


func _close_loop(points: PackedVector2Array) -> PackedVector2Array:
	var closed := PackedVector2Array(points)
	if closed.size() > 0:
		closed.append(closed[0])
	return closed
