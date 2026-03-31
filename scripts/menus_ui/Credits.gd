extends Control

signal closed_credits

var scroll_pos: float = 0.0
var max_scroll: float = -1200.0 # Adjust based on needed scroll length

@export var close_button: Button
@onready var scroll_area = %ScrollContainer
@export var passcode_input: LineEdit

func _ready() -> void:
	passcode_input.text_submitted.connect(_on_passcode_submitted)
	
	if Utility.dev_mode_enabled:
		passcode_input.text = ""
		passcode_input.placeholder_text = "Dev Mode Unlocked"


func _input(event: InputEvent) -> void:
	if not visible: return
	
	if Input.is_action_just_pressed("escape"):
			close_credits_menu()
	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		scroll_area.position.y += event.relative.y
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_area.position.y += 40
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_area.position.y -= 40
			
	# Update max scroll dynamically based on content height vs window height
	max_scroll = min(0.0, 540.0 - scroll_area.size.y)
	scroll_area.position.y = clamp(scroll_area.position.y, max_scroll - 100, 0)


func close_credits_menu() -> void:
	closed_credits.emit()

func _on_passcode_submitted(new_text: String) -> void:
	if new_text == "theinnerlight": # Hello There - Dr. Who
		Utility.dev_mode_enabled = true
		passcode_input.text = ""
		passcode_input.placeholder_text = "Dev Mode Unlocked"
		SaveManager.current_settings.cheats_activated = true
		SaveManager.save_settings()
	else:
		passcode_input.text = ""
		passcode_input.placeholder_text = "..."
