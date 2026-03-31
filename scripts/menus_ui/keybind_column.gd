extends VBoxContainer

const INPUT_BUTTON = preload("uid://byw6waphlkgng")
@onready var reset_button: Button = $ResetButton

var is_remapping: bool = false
var action_to_remap: String
var remapping_button: InputButton

signal keybind_changed(action: String, event: InputEvent)

var input_actions: Dictionary[String, String] = {
	"letter_q": "Minimap Out",
	"letter_e": "Minimap In",
	"overdrive": "Overdrive",
	"letter_m": "Galaxy Map"
}

func _ready() -> void:
	_create_action_list()


func _input(event: InputEvent) -> void:
	if is_remapping:
		if (event is InputEventKey
			or (event is InputEventMouseButton and event.pressed)):
				
				# Prevent left clicks being assigned
				if event is InputEventMouseButton and event.double_click: return
				elif event.is_action_pressed("left_click"): return
				elif event.is_action_pressed("right_click"): return
				
				InputMap.action_erase_events(action_to_remap)
				InputMap.action_add_event(action_to_remap, event)
				_update_action_list(remapping_button, event)
				
				keybind_changed.emit(action_to_remap, event)
				
				# Reset state
				is_remapping = false
				action_to_remap = ""
				remapping_button = null
				
				accept_event()

func _create_action_list(apply_defaults: bool = true) -> void:
	if apply_defaults:
		InputMap.load_from_project_settings()
	for button: InputButton in get_tree().get_nodes_in_group("InputButton"):
		button.queue_free()
	for action: String in input_actions:
		var button: InputButton = INPUT_BUTTON.instantiate()
		button.action_label.text = input_actions[action]
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			button.input_label.text = events[0].as_text().trim_suffix(" - Physical")
		else:
			button.input_label.text = ""
		add_child(button)
		button.pressed.connect(_on_input_button_selected.bind(button, action))
	move_child(reset_button, -1)

func sync_keybinds(settings: SettingsResource) -> void:
	settings.apply_keybinds()
	_create_action_list(false)  # Don't reload defaults — use restored bindings


func _update_action_list(button: InputButton, event) -> void:
	button.input_label.text = event.as_text().trim_suffix(" - Physical")


func _on_input_button_selected(button: InputButton, action: String) -> void:
	AudioManager.play_UI_click_sound()
	if !is_remapping:
		is_remapping = true
		action_to_remap = action
		remapping_button = button
		button.input_label.text = "Set Key..."


func _on_reset_button_pressed() -> void:
	AudioManager.play_UI_click_sound()
	# Clear all saved overrides from the resource
	SaveManager.current_settings.keybind_overrides.clear()
	SaveManager.save_settings()
	# Reload project defaults into InputMap and rebuild UI
	_create_action_list(true)
