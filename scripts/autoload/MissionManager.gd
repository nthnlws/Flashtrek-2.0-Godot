# MissionManager.gd
extends Node

#signal new_mission_generated(mission_data: MissionData)
signal mission_started(mission_data: MissionData)
signal mission_completed(mission_data: MissionData)
signal mission_failed(reason: String)
## Active mission details changed (e.g. bounty relocated).
signal mission_updated(mission_data: MissionData)
## An objective milestone was reached. `remaining` is the count left, or -1 if not applicable.
signal mission_progressed(mission_data: MissionData, remaining: int)
## Objectives are done and the mission waits on a starbase comms turn-in.
signal mission_ready_for_turn_in(mission_data: MissionData)

var Reputation: PlayerReputation = PlayerReputation.new()

# Stores the mission offered by a planet, before it's accepted.
var active_mission: MissionData = null
var pending_mission: MissionData = null

enum STATE {active_mission, pending_mission, no_mission}
var current_state: STATE = STATE.no_mission

## Nodes in this group get a mission marker on the minimap.
const MINIMAP_MARKER_GROUP: StringName = &"minimap_mission_marker"

## Chance per player warp that the bounty moves to a neighbouring system.
const BOUNTY_RELOCATE_CHANCE: float = 0.5


func _ready() -> void:
	SignalBus.component_resolved.connect(_on_component_resolved)
	SignalBus.system_changed.connect(_on_system_changed)


func replace_reputation_resource(new_rep: PlayerReputation) -> void:
	Reputation = new_rep


func is_mission_active(mission_id: String) -> bool:
	return active_mission != null and active_mission.mission_id == mission_id


# Leave arguments blank to generate a random mission
func generate_mission(random: bool = true, type: MissionData.MISSION_TYPE = MissionData.MISSION_TYPE.ANALYZE) -> void:
	var max_range: int = MissionGenerator.UNLIMITED_RANGE
	if is_instance_valid(LevelManager.player) and LevelManager.player.ship_stats:
		max_range = LevelManager.player.ship_stats.scaled_warp_range
	var new_mission: MissionData = MissionGenerator.generate_mission(
		LevelManager.current_system_data,
		LevelManager.galaxy_data,
		random,
		type,
		max_range
	)

	pending_mission = new_mission
	current_state = STATE.pending_mission


func accept_pending_mission() -> void:
	if current_state != STATE.pending_mission:
		printerr("No pending mission available to accept")
		return

	active_mission = pending_mission
	pending_mission = null
	current_state = STATE.active_mission

	var new_component_data: BaseComponentData = _create_mission_component(active_mission)

	# If the mission's target is the system currently loaded, spawn the
	# component immediately instead of waiting for the next system_changed.
	if new_component_data and active_mission.target_system == LevelManager.current_system_data and LevelManager.rootLevel:
		LevelManager.rootLevel.component_manager.inject_component(new_component_data)

	mission_started.emit(active_mission)


func _create_mission_component(mission: MissionData) -> BaseComponentData:
	var definition: ComponentDefinition = ComponentRegistry.get_for_mission_type(mission.type)
	if definition == null:
		return null # e.g. deliveries, handled by comms

	var system_data: SystemData = mission.target_system
	var data: BaseComponentData
	if definition.scope == ComponentDefinition.Scope.PLANET:
		var planet_data: PlanetData = system_data.get_planet_data(mission.target_planet_name)
		if planet_data == null:
			printerr("MissionManager: target planet '%s' not found in %s" % [mission.target_planet_name, system_data.system_name])
			return null
		data = planet_data.add_component(definition.component_id, mission)
	else:
		data = system_data.add_component(definition.component_id, mission)

	if data:
		data.mission_id = mission.mission_id
	return data


func report_progress(mission_id: String, remaining: int = -1) -> void:
	if is_mission_active(mission_id):
		mission_progressed.emit(active_mission, remaining)


func mark_ready_for_turn_in(mission_id: String) -> void:
	if not is_mission_active(mission_id) or active_mission.awaiting_turn_in:
		return
	active_mission.awaiting_turn_in = true
	mission_updated.emit(active_mission)
	mission_ready_for_turn_in.emit(active_mission)


func _on_component_resolved(data: BaseComponentData, success: bool) -> void:
	if data.mission_id.is_empty() or not is_mission_active(data.mission_id):
		return

	if success:
		complete_mission()
	else:
		fail_mission(data.failure_reason)


func complete_mission() -> void:
	if not active_mission:
		printerr('Attempted to finish mission in MissionManager with no active mission to complete')
		return

	var completed: MissionData = active_mission
	active_mission = null
	pending_mission = null
	current_state = STATE.no_mission

	_remove_mission_components(completed)

	mission_completed.emit(completed)

	var points: int = completed.reward
	SignalBus.updateScore.emit(points)
	SignalBus.reputation_change_triggered.emit(completed.faction_owner, points)

	if completed.follow_up:
		_start_follow_up(completed.follow_up, completed)


func fail_mission(reason: String = "") -> void:
	if not active_mission:
		return

	var failed: MissionData = active_mission
	active_mission = null
	pending_mission = null
	current_state = STATE.no_mission

	_remove_mission_components(failed)

	var failed_reason: String = reason if not reason.is_empty() else "Mission Failed"
	mission_failed.emit(failed_reason)
	SignalBus.changePopMessage.emit(failed_reason)


func _start_follow_up(follow_up: MissionData, parent: MissionData) -> void:
	# The planet that issued the parent mission relays the new orders
	if follow_up.origin_planet_name.is_empty():
		follow_up.origin_planet_name = parent.origin_planet_name
		follow_up.origin_planet_faction = parent.origin_planet_faction
	pending_mission = follow_up
	current_state = STATE.pending_mission
	accept_pending_mission()
	SignalBus.changePopMessage.emit("New orders: %s in the %s system" % [follow_up.title, follow_up.target_system.system_name])


## Removes unresolved components tagged with `mission`. Spawned ones resolve
## through ComponentManager so their nodes despawn. Call after clearing
## active_mission so the resulting component_resolved is ignored.
func _remove_mission_components(mission: MissionData) -> void:
	if mission.target_system == null:
		return

	var manager: ComponentManager = null
	if LevelManager.rootLevel:
		manager = LevelManager.rootLevel.component_manager

	var collections: Array = [mission.target_system.components]
	for planet: PlanetData in mission.target_system.planet_data:
		collections.append(planet.components)

	for collection: Array in collections:
		for data: BaseComponentData in collection.duplicate():
			if data.mission_id != mission.mission_id or data.is_finished:
				continue
			if manager and manager.is_spawned(data):
				data.mark_completed(false)
			else:
				collection.erase(data)


# --- Bounty ---

func _on_system_changed(new_system: SystemData) -> void:
	if not active_mission or active_mission.type != MissionData.MISSION_TYPE.BOUNTY:
		return

	var old_system: SystemData = active_mission.target_system
	if new_system == old_system or randf() > BOUNTY_RELOCATE_CHANCE:
		return

	var candidates: Array[SystemData] = []
	for neighbor_id: int in old_system.neighbor_ids:
		var neighbor: SystemData = LevelManager.galaxy_data.get_system(neighbor_id)
		if neighbor and neighbor != new_system and neighbor.system_index != GalaxyData.SPECIAL_SYSTEMS.Risa:
			candidates.append(neighbor)
	if candidates.is_empty():
		return

	var destination: SystemData = candidates.pick_random()
	for data: BaseComponentData in old_system.components.duplicate():
		if data.mission_id == active_mission.mission_id and data is BountyComponentData:
			old_system.components.erase(data)
			(data as BountyComponentData).relocate(destination)
			destination.components.append(data)

	active_mission.target_system = destination
	mission_updated.emit(active_mission)
	mission_progressed.emit(active_mission, -1)
	SignalBus.changePopMessage.emit("Intel: %s was sighted in the %s system" % [active_mission.bounty_name, destination.system_name])


# --- Contraband ---

func is_contraband_scanner(faction: Utility.FACTION) -> bool:
	return (active_mission != null
		and active_mission.type == MissionData.MISSION_TYPE.CONTRABAND
		and not active_mission.contraband_detected
		and active_mission.scanning_faction == faction)


func is_player_wanted_by(faction: Utility.FACTION) -> bool:
	return (active_mission != null
		and active_mission.type == MissionData.MISSION_TYPE.CONTRABAND
		and active_mission.contraband_detected
		and active_mission.scanning_faction == faction)


func report_contraband_detected() -> void:
	if not active_mission or active_mission.contraband_detected:
		return
	active_mission.contraband_detected = true
	var faction_name: String = Utility.FACTION.keys()[active_mission.scanning_faction].capitalize()
	SignalBus.changePopMessage.emit("Contraband detected! %s patrols are now hostile" % faction_name)
