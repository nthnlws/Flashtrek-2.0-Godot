extends Control

@onready var comms_message: RichTextLabel = $Comms_message
@onready var close_button: TextButton = $CloseButton

var ship_name: String
var current_planet: Planet

func _ready() -> void:
	ship_name = Utility.player_name
	_connect_signals()
	self.visible = false


func _connect_signals() -> void:
	# --- UI & PLAYER SIGNALS ---
	SignalBus.enteredPlanetComm.connect(_on_enter_comms_range)
	SignalBus.exitedPlanetComm.connect(_on_exit_comms)
	SignalBus.TopRight_clicked.connect(_on_cargo_beam_pressed)
	SignalBus.BottomLeft_clicked.connect(_on_open_comms_pressed)
	SignalBus.entering_galaxy_warp.connect(close_comms)


#region Player Comms
# --- UI VISIBILITY AND STATE ---
func open_comms() -> void:
	if not current_planet:
		return
	var comms_component: PlanetCommunicationComponent = current_planet.get_node_or_null("ComponentFolder/CommunicationComponent")
	if not comms_component:
		return
	
	self.visible = true
	SignalBus.toggleQ3HUD.emit("off") # Turn off Q3 pulse (Comm Available)
	
	# 1. Get the formatted text from the planet
	var message: String = comms_component.request_hail(ship_name)
	update_comms_message(message)
	
	# 2. Check resulting state to toggle UI elements
	# If the planet just generated a pending mission, we need the "Beam/Accept" button to pulse
	if MissionManager.current_state == MissionManager.STATE.pending_mission:
		SignalBus.toggleQ2HUD.emit("on")

func close_comms() -> void:
	visible = false
	if close_button:
		close_button.pressed = false
		close_button._update_color()

# --- BUTTON PRESS HANDLERS ---
func _on_reroll_pressed() -> void:
	AudioManager.play_UI_click_sound()
	# If we are pending, re-opening comms triggers request_hail again,
	# which triggers a new generation inside the Planet script logic.
	if visible and current_planet and MissionManager.current_state != MissionManager.STATE.active_mission:
		open_comms()


func _on_close_ui_pressed() -> void:
	AudioManager.play_UI_click_sound()
	close_comms()


func _on_open_comms_pressed() -> void:
	open_comms()


func _on_cargo_beam_pressed() -> void:
	var comm_component: PlanetData.PlanetComponentType = PlanetData.PlanetComponentType.COMMUNICATION
	if not self.visible or not current_planet or not current_planet.has_component(comm_component):
			return
	
	# Attempt to interact (Accept Mission or Complete Mission)
	var response: String = current_planet.get_component(comm_component).attempt_interaction(ship_name)
	
	if not response.is_empty():
		SignalBus.toggleQ2HUD.emit("off") # Turn off beam pulse
		update_comms_message(response)

# --- UTILITY ---

func update_comms_message(message: String) -> void:
	comms_message.text = message

func _on_enter_comms_range(planet_node: Node2D) -> void:
	if planet_node is Planet:
		current_planet = planet_node as Planet

func _on_exit_comms(_planet: Node2D) -> void:
	current_planet = null
	close_comms()

#endregion

#region Survey Mission
