# MissionManager.gd
extends Node

#signal new_mission_generated(mission_data: MissionData)
signal mission_started(mission_data: MissionData)
signal mission_completed(mission_data: MissionData)
signal mission_failed(reason: String)

var Reputation: PlayerReputation = PlayerReputation.new()

# Stores the mission offered by a planet, before it's accepted.
var active_mission: MissionData = null
var pending_mission: MissionData = null

enum STATE {active_mission, pending_mission, no_mission}
var current_state: STATE = STATE.no_mission

func replace_reputation_resource(new_rep: PlayerReputation) -> void:
	Reputation = new_rep


# Leave arguments blank to generate a random mission
func generate_mission(random: bool = true, type: MissionData.MISSION_TYPE = MissionData.MISSION_TYPE.ANALYZE) -> void:
	var new_mission: MissionData = MissionGenerator.generate_mission(
		LevelManager.current_system_data,
		LevelManager.galaxy_data,
		random,
		type
	)
	
	pending_mission = new_mission
	current_state = STATE.pending_mission


func accept_pending_mission() -> void:
	if current_state != STATE.pending_mission:
		printerr("No pending mission available to accept")
		return
	
	active_mission = pending_mission
	
	# Spawn Planet/System components as needed
	var system_data: SystemData = active_mission.target_system
	var planet_data: PlanetData = system_data.get_planet_data(active_mission.target_planet_name)
	
	if active_mission.type == MissionData.MISSION_TYPE.ANALYZE:
		planet_data.add_component(Utility.PlanetComponentType.ANALYZE, active_mission)
	# elif active_mission.type == MissionData.MISSION_TYPE.DELIVERY:
	# 	planet_data.add_component(Utility.PlanetComponentType.DELIVER, active_mission)
	elif active_mission.type == MissionData.MISSION_TYPE.KILL_FACTION:
		system_data.add_component(Utility.SystemComponentType.KILL_FACTION, active_mission)
	elif active_mission.type == MissionData.MISSION_TYPE.CONTAINER:
		system_data.add_component(Utility.SystemComponentType.CONTAINER, active_mission)
	elif active_mission.type == MissionData.MISSION_TYPE.ESCORT:
		system_data.add_component(Utility.SystemComponentType.ESCORT, active_mission)
	
	mission_started.emit(active_mission)
	
	current_state = STATE.active_mission # Update state


func complete_mission() -> void:
	if active_mission:
		#print("Mission Completed at Planet: ", active_mission.target_planet_name)
		mission_completed.emit(active_mission)
		
		current_state = STATE.no_mission
		
		var points: int = active_mission.reward
		var mission_faction: Utility.FACTION = LevelManager.current_system_data.faction
		SignalBus.updateScore.emit(points)
		match mission_faction:
			Utility.FACTION.FEDERATION:
				SignalBus.reputation_change_triggered.emit(Utility.FACTION.FEDERATION, points)
			Utility.FACTION.KLINGON:
				SignalBus.reputation_change_triggered.emit(Utility.FACTION.KLINGON, points)
			Utility.FACTION.ROMULAN:
				SignalBus.reputation_change_triggered.emit(Utility.FACTION.ROMULAN, points)
			Utility.FACTION.NEUTRAL:
				SignalBus.reputation_change_triggered.emit(Utility.FACTION.NEUTRAL, points)
	
		pending_mission = null
		active_mission = null
	else: printerr('No active mission to complete')


func fail_mission() -> void:
	if active_mission:
		var failed_reason: String = "Mission Failed"
		if active_mission.type == MissionData.MISSION_TYPE.ESCORT:
			failed_reason = "Escorting ship died, mission failed"
		mission_failed.emit(failed_reason)
		
		current_state = STATE.no_mission
		pending_mission = null
		active_mission = null
