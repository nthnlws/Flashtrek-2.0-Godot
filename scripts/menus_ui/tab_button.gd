@tool
class_name TabButton
extends Control

# Signals
signal tab_clicked(node_name:String)
signal delete_slot_clicked(node_name:String)
signal hover_started
signal hover_ended
signal entered_management_state
signal exited_management_state


# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_node_ready(): 
			_update_visual_state()

@export var text: String = "System":
	set(value):
		text = value
		if _label: 
			_label.text = value
		if is_node_ready(): 
			_update_size() 

@export_group("Visuals")
@export var button_color: Color = Color.from_rgba8(212, 212, 119, 255):
	set(value):
		button_color = value
		if is_node_ready(): 
			_update_visual_state()

@export var text_default_color: Color = Color(0.0, 0.0, 0.0, 1.0)
@export var text_hover_color: Color = Color(1.0, 1.0, 1.0)
@export var text_pressed_color: Color = Color(0.8, 0.7, 0.0, 1.0)

@export_group("Animation")
@export var starting_position: Vector2 = Vector2(-36.0, 0.0)
@export var slide_offset: Vector2 = Vector2(36.0, 0.0)
@export var animation_duration: float = 0.2

# ------------------------------------------------------------------------------
# Internal State & References
# ------------------------------------------------------------------------------
@onready var _sliding_container: Control = $SlidingContainer
@onready var _background: CanvasItem = $SlidingContainer/Background
@onready var _label: Label = $SlidingContainer/Label
@onready var red_box: ColorRect = $SlidingContainer/RedBox

var _is_hovered: bool = false
var _is_pressed: bool = false
var _active_tween: Tween

func _ready() -> void:
	if is_inside_tree(): # Turn red box on for in game
		red_box.visible = true
	if _label:
		_label.text = text
	
	_sliding_container.position = starting_position
	#if _sliding_container:
		#_default_pos = _sliding_container.position
	
	_update_size()
	_update_visual_state()


func _on_red_box_child_clicked() -> void:
	delete_slot_clicked.emit(self.name)

# ------------------------------------------------------------------------------
# Visuals & Animation
# ------------------------------------------------------------------------------

func enter_management_state() -> void:
	#print("entering management state")
	enabled = false
	var tween:Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var box_target_pos: Vector2 = Vector2(36, 0)
	
	tween.tween_property(red_box, "position", box_target_pos, animation_duration)
	
	var button_target_pos:Vector2 = starting_position + slide_offset
	var tween2:Tween = create_tween()
	tween2.tween_property(_sliding_container, "position", button_target_pos, animation_duration)
	
	await tween.finished
	entered_management_state.emit()


func exit_management_state() -> void:
	#print("exiting management state")
	enabled = true
	var tween:Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var target_pos: Vector2 = Vector2(-72, 0)
	
	tween.tween_property(red_box, "position", target_pos, animation_duration)
	
	var button_target_pos:Vector2 = starting_position
	var tween2:Tween = create_tween()
	tween2.tween_property(_sliding_container, "position", button_target_pos, animation_duration)
	
	await tween.finished
	exited_management_state.emit()


func _update_visual_state() -> void:
	if not _background or not _label:
		return

	_background.modulate = button_color
	
	var target_text_color: Color = text_default_color
	if not enabled:
		target_text_color = text_default_color.darkened(0.5)
	elif _is_pressed:
		target_text_color = text_pressed_color
	elif _is_hovered:
		target_text_color = text_hover_color
	
	_label.modulate = target_text_color


func _update_size() -> void:
	if _background and _background is Control:
		custom_minimum_size = _background.size
		size = _background.size


func _animate_slide(slide_out: bool) -> void:
	if not _sliding_container: 
		return
	
	if _active_tween:
		_active_tween.kill()
	
	_active_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var target_pos: Vector2 = starting_position + slide_offset if slide_out else starting_position
	
	_active_tween.tween_property(
		_sliding_container, 
		"position", 
		target_pos, 
		animation_duration
	)

# ------------------------------------------------------------------------------
# Input Handling
# ------------------------------------------------------------------------------

func _has_point(point: Vector2) -> bool:
	if not enabled or not _background:
		return Rect2(Vector2.ZERO, size).has_point(point)
	
	# 1. Convert Local Point (TabButton) -> Global Space
	# We multiply the node's Global Transform Matrix by the local point
	var global_point: Vector2 = get_global_transform() * point
	
	# 2. Convert Global Space -> Background Local Space
	# We use the affine inverse of the Background's transform to go "backwards" into its local space
	var point_in_bg_space: Vector2 = _background.get_global_transform().affine_inverse() * global_point
	
	# 3. Check collisions
	if _background is Polygon2D:
		return Geometry2D.is_point_in_polygon(point_in_bg_space, _background.polygon)
		
	elif _background is Control:
		# Check if point is inside the rect (0, 0, width, height)
		var bg_rect: Rect2 = Rect2(Vector2.ZERO, _background.size)
		return bg_rect.has_point(point_in_bg_space)
	
	return Rect2(Vector2.ZERO, size).has_point(point)


func _gui_input(event: InputEvent) -> void:
	if not enabled: 
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed = true
			accept_event()
			_update_visual_state()
		elif _is_pressed:
			_is_pressed = false
			accept_event()
			tab_clicked.emit(self.name)
			_update_visual_state()

func _on_mouse_entered() -> void:
	if not enabled: return
	_is_hovered = true
	hover_started.emit()
	_animate_slide(true)
	_update_visual_state()

func _on_mouse_exited() -> void:
	if not enabled: return
	_is_hovered = false
	hover_ended.emit()
	_animate_slide(false)
	_is_pressed = false
	_update_visual_state()
