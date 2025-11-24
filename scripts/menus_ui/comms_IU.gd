extends Control

@onready var comms_message: RichTextLabel = $Comms_message

var ship_name: String
var current_planet: Node2D # Current planet with comms open

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

	# --- MISSION MANAGER SIGNALS ---
	MissionManager.mission_completed.connect(_on_mission_completed)
	MissionManager.mission_delivery_point_reached.connect(_on_mission_delivery_point_reached)


# --- UI VISIBILITY AND STATE ---
func open_comms() -> void:
	var messsage_strings:MissionData = MissionData.new()
	if not current_planet: return
	
	self.visible = true
	SignalBus.toggleQ3HUD.emit("off") # Turn off Q3 pulse
	
	if (MissionManager.current_state == MissionManager.STATE.no_mission
		or MissionManager.current_state == MissionManager.STATE.pending_mission):
			MissionManager.generate_mission(current_planet.name)
			update_comms_message(_on_new_mission_generated(MissionManager.pending_mission))
	elif MissionManager.current_state == MissionManager.STATE.active_mission:
		if MissionManager.active_mission.targetPlanet == current_planet.name:
			var text:String = messsage_strings.confirmation_complete_prompts.pick_random()
			update_comms_message(text)
		else:
			var text:String = messsage_strings.cargo_full_messages.pick_random()
			update_comms_message(text)


func close_comms() -> void:
	visible = false
	MissionManager.clear_missions()


# --- BUTTON PRESS HANDLERS ---
func _on_reroll_pressed() -> void:
	SignalBus.UIclickSound.emit()
	if visible and current_planet and MissionManager.current_state != MissionManager.STATE.active_mission:
		MissionManager.generate_mission(current_planet.name)
		update_comms_message(_on_new_mission_generated(MissionManager.pending_mission))


func _on_close_ui_pressed() -> void:
	SignalBus.UIclickSound.emit()
	close_comms()

func _on_open_comms_pressed() -> void:
	open_comms()

func _on_cargo_beam_pressed() -> void:
	SignalBus.toggleQ2HUD.emit("off") # Turn off beam pulse
	
	if MissionManager.current_state == MissionManager.STATE.pending_mission:
		MissionManager.accept_pending_mission()
		var mission:MissionData = MissionManager.active_mission
		var text:String = "Mission accepted! Head to [color=#6699CC]%s[/color] in the [color=#FFCC66]%s[/color] system." % [mission.targetPlanet, mission.targetSystem.system_name]
		update_comms_message(text)
		SignalBus.missionAccepted.emit(mission)
	elif (MissionManager.current_state == MissionManager.STATE.active_mission
		and MissionManager.active_mission.targetPlanet == current_planet.name):
		MissionManager.complete_mission()


func _on_new_mission_generated(mission_data: MissionData) -> String:
	SignalBus.toggleQ2HUD.emit("on") # Turn on beam pulse
	var data: Dictionary = {
		"planet": "[color=#6699CC]" + current_planet.name + "[/color]",
		"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
		"target_planet": "[color=#FFCC66]" + mission_data.targetPlanet + "[/color]",
		"target_system": "[color=#FFCC66]" + mission_data.targetSystem.system_name + "[/color]",
		"item_name": "[color=#1DCC4B]" + mission_data.cargo + "[/color]",
		"random_confirm_query": mission_data.message,
	}
	var template_text = "Welcome to {planet}, {ship_name}, {target_planet} in the {target_system} system needs a shipment of {item_name}. {random_confirm_query}"
	return template_text.format(data)


func _on_mission_delivery_point_reached(planet_name: String) -> void:
	SignalBus.toggleQ2HUD.emit("on")
	update_comms_message(MissionManager.confirmation_complete_prompts.pick_random())


func _on_mission_completed(mission_data: MissionData) -> void:
	var mission_strings:MissionData = MissionData.new()
	var data: Dictionary = {
		"planet": "[color=#6699CC]" + mission_data.targetPlanet + "[/color]",
		"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
		}
	
	match current_planet.planetFaction:
		Utility.FACTION.FEDERATION:
			data.random_confirm = mission_strings.federation_thankYou.pick_random()
		Utility.FACTION.KLINGON:
			data.random_confirm = mission_strings.klingon_thankYou.pick_random()
		Utility.FACTION.ROMULAN:
			data.random_confirm = mission_strings.romulan_thankYou.pick_random()
	
	var template_text: String = "Welcome to {planet}, {ship_name}, {random_confirm}"
	var formatted_text: String = template_text.format(data)
	update_comms_message(formatted_text)

# --- UTILITY ---

func update_comms_message(message: String) -> void:
	comms_message.bbcode_text = message

func _on_enter_comms_range(planet: Node2D) -> void:
	current_planet = planet

func _on_exit_comms(planet: Node2D) -> void:
	current_planet = null
	close_comms()
