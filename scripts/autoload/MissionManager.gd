# MissionManager.gd
extends Node

signal new_mission_generated(mission_data: MissionData)
signal mission_started(mission_data: MissionData)
signal mission_completed(mission_data: MissionData)
signal mission_rejected(reason: String)

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
				SignalBus.reputationChanged.emit(Utility.FACTION.FEDERATION, Reputation.FederationRep + points)
			Utility.FACTION.KLINGON:
				SignalBus.reputationChanged.emit(Utility.FACTION.KLINGON, Reputation.KlingonRep + points)
			Utility.FACTION.ROMULAN:
				SignalBus.reputationChanged.emit(Utility.FACTION.ROMULAN, Reputation.RomulanRep + points)
			Utility.FACTION.NEUTRAL:
				SignalBus.reputationChanged.emit(Utility.FACTION.NEUTRAL, Reputation.NeutralRep + points)
	
		pending_mission = null
		active_mission = null
	else: printerr('No active mission to complete')


func _recalculate_current_faction() -> Utility.FACTION:
	if max(Reputation.FederationRep, Reputation.KlingonRep, Reputation.RomulanRep) <= 5000:
		return Utility.FACTION.NEUTRAL
	elif Reputation.FederationRep >= max(Reputation.KlingonRep, Reputation.RomulanRep):
		return Utility.FACTION.FEDERATION
	elif Reputation.KlingonRep >= max(Reputation.FederationRep, Reputation.RomulanRep):
		return Utility.FACTION.KLINGON
	elif Reputation.RomulanRep >= max(Reputation.FederationRep, Reputation.KlingonRep):
		return Utility.FACTION.ROMULAN
	else:
		push_error("Current faction calculation failed, current faction unknown")
		return Utility.FACTION.NEUTRAL
