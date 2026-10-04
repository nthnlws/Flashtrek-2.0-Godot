extends PlanetComponent
class_name PlanetCommunicationComponent

var component_data: CommunicationComponentData
var is_active_session: bool = false

enum UI_STATE { PENDING, READY_TO_BEAM, ERROR, ACCEPTED }

func initialize_planet_component(data: PlanetComponentData) -> void:
	component_data = data as CommunicationComponentData

	SignalBus.CommsButton_clicked.connect(_check_player_range)
	SignalBus.comms_action_taken.connect(_on_comms_action_taken)
	SignalBus.entering_galaxy_warp.connect(_close_session)

func _check_player_range() -> void:
	if LevelManager.player.nearest_planet == owning_planet_data:
		# Toggle logic: Close if open, open if closed
		if is_active_session:
			_close_session()
		else:
			_start_hail(LevelManager.player.ship_stats.ship_name)

func _start_hail(player_ship_name: String) -> void:
	is_active_session = true
	var message: String = ""
	var state: UI_STATE = UI_STATE.ERROR

	if MissionManager.current_state == MissionManager.STATE.active_mission:
		if MissionManager.active_mission.is_delivery_type() and MissionManager.active_mission.target_planet_name == owning_planet_data.name:
			message = MissionGenerator.confirmation_complete_prompts.pick_random()
			state = UI_STATE.READY_TO_BEAM # Dedicated beam state
		else:
			message = MissionGenerator.cargo_full_messages.pick_random()
			state = UI_STATE.ERROR # Informational only, allow closing

	elif MissionManager.current_state in [MissionManager.STATE.no_mission, MissionManager.STATE.pending_mission]:
		MissionManager.generate_mission()
		message = _format_mission_offer(MissionManager.pending_mission, player_ship_name)
		state = UI_STATE.PENDING # Dedicated accept state

	if message.is_empty():
		message = "Channel open. No data available."
		state = UI_STATE.ERROR

	SignalBus.request_comms_popup.emit(message, state as int)

## Called by comms_ui scene upon reroll, close, beam, or accept mission button clicked
func _on_comms_action_taken(action: String) -> void:
	if not is_active_session:
		return

	var player_ship_name: String = LevelManager.player.ship_stats.ship_name

	match action:
		"accept":
			_accept_mission()
		"beam":
			_beam_cargo()
		"reroll":
			_start_hail(player_ship_name)
		"close":
			_close_session()

func _accept_mission() -> void:
	if MissionManager.current_state == MissionManager.STATE.pending_mission:
		# The faction popup voices the acceptance as this planet
		MissionManager.pending_mission.origin_planet_name = owning_planet_data.name
		MissionManager.pending_mission.origin_planet_faction = owning_planet_data.faction
		_close_session()
		MissionManager.accept_pending_mission()

func _beam_cargo() -> void:
	var mission: MissionData = MissionManager.active_mission
	if MissionManager.current_state == MissionManager.STATE.active_mission and mission.is_delivery_type() and mission.target_planet_name == owning_planet_data.name:
		# The faction popup voices the completion as this planet
		_close_session()
		MissionManager.complete_mission()

func _close_session() -> void:
	if is_active_session:
		is_active_session = false
		SignalBus.close_comms_popup.emit()

func _on_comm_area_body_entered(body: Node2D) -> void:
	if body.has_method("changePlanet"):
		body.changePlanet(owning_planet_data)

func _on_comm_area_body_exited(body: Node2D) -> void:
	if body.has_method("changePlanet"):
		body.changePlanet(null)
		if is_active_session:
			_close_session()

# --- FORMATTING HELPERS ---
func _format_mission_offer(mission: MissionData, ship_name: String) -> String:
	var data: Dictionary = {
		"planet": "[color=#FFCC66]" + owning_planet_data.name + "[/color]",
		"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
		"target_planet": "[color=#FFCC66]" + mission.target_planet_name + "[/color]",
		"target_system": _get_faction_color_string(mission.target_system.faction, mission.target_system.system_name),
		"item_name": "[color=#1DCC4B]" + mission.cargo + "[/color]",
		"random_confirm_query": mission.confirm_message,
		"mission_description": mission.description
	}
	var template: String = "Welcome to {planet}, {ship_name}, {mission_description}. {random_confirm_query}"
	return template.format(data)

func _get_faction_color_string(faction: int, text: String) -> String:
	var color_code: String = Utility.UI_yellow # Default
	match faction:
		Utility.FACTION.FEDERATION: color_code = Utility.fed_blue
		Utility.FACTION.ROMULAN: color_code = Utility.rom_green
		Utility.FACTION.KLINGON: color_code = Utility.klin_red
	return color_code + text + "[/color]"
