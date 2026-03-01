extends VBoxContainer

signal button_clicked

var current_system: String = "Solarus"
var current_mission_type: MissionData.MISSION_TYPE = MissionData.MISSION_TYPE.KILL_FACTION
var current_faction: Utility.FACTION = Utility.FACTION.FEDERATION

func _ready() -> void:
	if Utility.dev_mode_enabled:
		self.visible = true


func _on_planet_tp_button_pressed() -> void:
	var current_player_pos: Vector2 = LevelManager.player.global_position
	var shortest_distance: float = INF
	var chosen_position: Vector2 = Vector2.ZERO
	
	for planet: Planet in LevelManager.planets:
		var dist: float = current_player_pos.distance_to(planet.global_position)
		if dist < shortest_distance:
			shortest_distance = dist
			chosen_position = planet.global_position
	
	# Only emit if we actually found a position (prevents TP to 0,0 if list is empty)
	if shortest_distance != INF:
		SignalBus.teleport_player.emit(chosen_position)
		button_clicked.emit()


func _on_next_planet_tp_button_pressed() -> void:
	# Safety check for at least 2 planets
	if LevelManager.planets.size() <= 1:
		print("Not enough planets to teleport.")
		return

	var current_player_pos: Vector2 = LevelManager.player.global_position
	var shortest_distance: float = INF
	var current_planet: Planet

	# Find the closest planet
	for planet: Planet in LevelManager.planets:
		var dist: float = current_player_pos.distance_to(planet.global_position)
		if dist < shortest_distance:
			shortest_distance = dist
			current_planet = planet
	
	var next_planet: Planet = current_planet
	while next_planet == current_planet:
		next_planet = LevelManager.planets.pick_random()
	
	SignalBus.teleport_player.emit(next_planet.global_position)
	button_clicked.emit()


func _on_change_system_button_pressed(system:String = "Solarus") -> void:
	var selected_system: SystemData = LevelManager.galaxy_data.get_system_by_name(current_system)
	SignalBus.galaxy_warp_finished.emit(selected_system)
	button_clicked.emit()


func _on_start_mission_button_pressed() -> void:
	MissionManager.generate_mission(false, current_mission_type)
	MissionManager.accept_pending_mission()
	button_clicked.emit()


func _on_spawn_neutral_button_pressed() -> void:
	pass # Replace with function body.


func _on_spawn_faction_button_pressed() -> void:
	pass # Replace with function body.


func _on_factions_item_selected(index: int) -> void:
	current_faction = index as Utility.FACTION


func _on_mission_type_item_selected(index: int) -> void:
	current_mission_type = index as MissionData.MISSION_TYPE


func _on_system_name_text_changed(new_text: String) -> void:
	current_system = new_text


func _on_complete_mission_button_pressed() -> void:
	MissionManager.complete_mission()
	button_clicked.emit()
