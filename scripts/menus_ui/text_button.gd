class_name TextButton extends Label

signal button_hovered
signal button_pressed

@export var default_color: Color
@export var hover_color: Color
@export var pressed_color: Color

@export var enabled: bool = true
var hover: bool = false
var pressed: bool = false

func _on_mouse_entered() -> void :
	hover = true
	button_hovered.emit()

func _on_mouse_exited() -> void :
	hover = false

func _process(delta: float) -> void :
	if pressed:
		modulate = pressed_color
		return
	elif !enabled or !is_visible_in_tree():
		modulate = default_color
		return
	if hover:
		if Input.is_action_just_pressed("left_click"):
			press()
		modulate = hover_color
	else:
		modulate = default_color

func press() -> void :
	if pressed: return
	pressed = true
	await get_tree().process_frame
	button_pressed.emit()
	await get_tree().create_timer(0.2).timeout
	pressed = false

func set_enabled(state: bool) -> void :
	enabled = state
