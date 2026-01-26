# MissionManager.gd
extends Node

#signal new_mission_generated(mission_data: MissionData)
signal mission_started(mission_data: MissionData)
signal mission_completed(mission_data: MissionData)
#signal mission_rejected(reason: String)

var Reputation: PlayerReputation = PlayerReputation.new()

# Stores the mission offered by a planet, before it's accepted.
var active_mission: MissionData = null
var pending_mission: MissionData = null

enum STATE { active_mission, pending_mission, no_mission }
var current_state:STATE = STATE.no_mission


func generate_mission() -> void:
	var new_mission:MissionData = MissionGenerator.generate_random_mission(
		LevelManager.current_system_data,
		LevelManager.galaxy_data
	)
	
	pending_mission = new_mission
	current_state = STATE.pending_mission



func accept_pending_mission() -> void:
	if current_state != STATE.pending_mission:
		printerr("No pending mission available to accept")
		return
	
	active_mission = pending_mission
	
	if active_mission.type == MissionData.MISSION_TYPE.ANALYSIS:
		var planet_data: PlanetData = active_mission.target_system.get_planet_data(active_mission.target_planet_name)
		planet_data.add_AnalyzeComponent()
	if active_mission.type == MissionData.MISSION_TYPE.KILL_FACTION:
		active_mission.target_system.add_KillEnemiesComponent()
	
	mission_started.emit(active_mission)
	
	current_state = STATE.active_mission # Update state
	
	## Add container data to target system in order to trigger spawn when entering system
		#new_mission.target_system.add_mission_container(new_mission.container_target)


func complete_mission() -> void:
	if active_mission:
		#print("Mission Completed at Planet: ", active_mission.target_planet_name)
		mission_completed.emit(active_mission)
		
		current_state = STATE.no_mission
		
		var points:int = active_mission.reward
		var mission_faction:Utility.FACTION = LevelManager.current_system_data.faction
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
