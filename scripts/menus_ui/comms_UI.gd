extends Control

@onready var comms_message: RichTextLabel = $CommsMessage
@onready var interact_button: TextButton = $InteractButton

const ACCEPT_STRING: String = "ACCEPT
            MISSION"
const CLOSE_STRING: String = "CLOSE
            COMMS"
enum STATE { PENDING, ERROR, ACCEPTED }
var current_state: STATE = STATE.PENDING

signal mission_accepted
signal mission_rerolled


var ship_name: String
var current_planet: Planet


func _ready() -> void:
	ship_name = Utility.player_name
	_connect_signals()
	self.visible = false


func _connect_signals() -> void:
	SignalBus.CommsButton_clicked.connect(_on_open_comms_pressed)
	SignalBus.entering_galaxy_warp.connect(close_comms)


# --- UI VISIBILITY AND STATE ---
func open_comms() -> void:
	if not current_planet:
		return
	
	if not current_planet.component_manager.has_component_type(&"communication"):
		return
		
	var comms_component = current_planet.component_manager.get_component_by_type(&"communication")
	if not is_instance_valid(comms_component):
		return
	
	self.visible = true
	# Old HUD button animation toggle
	#SignalBus.toggleQ3HUD.emit("off") # Turn off Q3 pulse (Comm Available)
	
	# 1. Get the formatted text from the planet
	var message: String = comms_component.request_hail(ship_name)
	updateMessage(message)
	
	# 2. Check resulting state to toggle UI elements
	# If the planet just generated a pending mission, we need the "Beam/Accept" button to pulse
	if MissionManager.current_state == MissionManager.STATE.pending_mission:
		# Old button animation
		pass

func close_comms() -> void:
	visible = false
	if interact_button:
		interact_button.pressed = false
		interact_button._update_color()


# --- BUTTON PRESS HANDLERS ---
func _on_reroll_pressed() -> void:
	AudioManager.play_UI_click_sound()
	# If we are pending, re-opening comms triggers request_hail again,
	# which triggers a new generation inside the Planet script logic.
	if visible and current_planet and MissionManager.current_state != MissionManager.STATE.active_mission:
		open_comms()


func _on_open_comms_pressed() -> void:
	open_comms()


func _on_mission_accepted() -> void:
	if not self.visible or not current_planet or not current_planet.component_manager.has_component_type(&"communication"):
			return
	
	# Attempt to interact (Accept Mission or Complete Mission)
	var response: String = current_planet.attempt_interaction(ship_name)
	
	if not response.is_empty():
		updateMessage(response)


# --- UTILITY ---
func updateMessage(message: String) -> void:
	comms_message.text = message

func _on_enter_comms_range(planet_node: Node2D) -> void:
	if planet_node is Planet:
		current_planet = planet_node as Planet

func _on_exit_comms(_planet: Node2D) -> void:
	current_planet = null
	close_comms()


func update_state(new_state: STATE) -> void:
	if new_state == STATE.PENDING:
		interact_button.text = ACCEPT_STRING
	elif new_state == STATE.ERROR:
		interact_button.text = CLOSE_STRING
	elif new_state == STATE.ACCEPTED:
		interact_button.text = CLOSE_STRING
