extends Resource
class_name SettingsResource

@export_group("Video")
@export var vsync_setting: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED

@export_group("Audio")
@export var master_volume: float = 0.8
@export var music_volume: float = 0.8
@export var effects_volume: float = 0.8
@export var menus_volume: float = 0.5

@export_group("Game")
@export var ui_scale: float = 0.7
@export var warnings_disabled: bool = false

@export_group("Keybinds")
# Stores action name → serialized event string for persistence
# Full InputEvent cannot be stored in a resource directly so we
# store the scancode/button index and reconstruct on load
@export var keybind_overrides: Dictionary[String, int] = {}

func save_keybind(action: String, event: InputEvent) -> void:
	if event is InputEventKey:
		keybind_overrides[action] = event.keycode
	elif event is InputEventMouseButton:
		keybind_overrides[action] = -event.button_index  # Negative to distinguish from keycodes

func apply_keybinds() -> void:
	for action: String in keybind_overrides:
		var stored: int = keybind_overrides[action]
		var event: InputEvent
		if stored >= 0:
			var key_event := InputEventKey.new()
			key_event.keycode = stored
			event = key_event
		else:
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = -stored
			event = mouse_event
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event)
