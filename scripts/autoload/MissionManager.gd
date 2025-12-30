# MissionManager.gd
extends Node

#signal new_mission_generated(mission_data: MissionData)
signal mission_started(mission_data: MissionData)
signal mission_completed(mission_data: MissionData)
#signal mission_rejected(reason: String)

var Reputation: PlayerReputation = PlayerReputation.new()

# This will store the mission offered by a planet, before it's accepted.
var active_mission: MissionData = null
var pending_mission: MissionData = null

enum STATE { active_mission, pending_mission, no_mission }
var current_state:STATE = STATE.no_mission


func generate_mission() -> void:
	var mission:MissionData = MissionData.new()
	var new_mission = mission.generate_mission_offer()
	pending_mission = new_mission
	
	current_state = STATE.pending_mission # Update state


func accept_pending_mission() -> void:
	if current_state != STATE.pending_mission:
		printerr("No pending mission available to accept")
		return
	
	active_mission = pending_mission
	mission_started.emit(active_mission)
	
	current_state = STATE.active_mission # Update state


func complete_mission() -> void:
	if active_mission:
		#print("Mission Completed at Planet: ", active_mission.targetPlanet)
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
