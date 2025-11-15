# MissionManager.gd
extends Node

signal new_mission_generated(mission_data: MissionData)
signal mission_started(mission_data: MissionData)
signal mission_completed(mission_data: MissionData)
signal mission_rejected(reason: String)
signal mission_delivery_point_reached(planet_name: String)


# This will store the mission offered by a planet, before it's accepted.
var active_mission: MissionData = null
var pending_mission: MissionData = null

enum STATE { active_mission, pending_mission, no_mission }
var current_state:STATE = STATE.no_mission


func generate_mission(source_planet_name:String) -> void:
	var mission:MissionData = MissionData.new()
	var new_mission = mission.generate_mission_offer(source_planet_name)
	pending_mission = new_mission
	
	current_state = STATE.pending_mission # Update state


func accept_pending_mission() -> void:
	if current_state != STATE.pending_mission:
		printerr("No pending mission available to accept")
		return
	
	active_mission = pending_mission
	mission_started.emit(active_mission)
	pending_mission = null
	
	current_state = STATE.active_mission # Update state


func complete_mission() -> void:
	if active_mission:
		print("Mission Completed at Planet: ", active_mission.targetPlanet)
		mission_completed.emit(active_mission)
		active_mission = null
		
		current_state = STATE.no_mission
	
	else: printerr('No active mission to complete')


func clear_missions() -> void:
	active_mission = null
	pending_mission = null
	current_state = STATE.no_mission
