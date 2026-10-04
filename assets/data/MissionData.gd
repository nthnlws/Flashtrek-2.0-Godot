# mission_data.gd
class_name MissionData
extends Resource

# Append only - int values are stored in ComponentDefinition.mission_type.
enum MISSION_TYPE { DELIVERY, CONTAINER, KILL_FACTION, ESCORT, ANALYZE, SALVAGE, RESCUE, BOUNTY, SENSOR_SWEEP, DEFENSE, CONTRABAND }

@export var confirm_message:String

# --- Common Data for ALL Missions ---
@export_group("Core Info")
@export var mission_id: String
@export var type: MISSION_TYPE
@export var title: String
@export_multiline var description: String
@export var faction_owner: Utility.FACTION
@export var reward: int = 0
@export var accepted_time: int = 0
## Auto-accepted when this mission completes.
@export var follow_up: MissionData

# --- Location Data ---
@export_group("Target Location")
@export var target_system: SystemData
@export var target_planet_name: String # Optional
## Planet whose comms issued the mission - it voices the accept popup. Empty for debug missions.
@export var origin_planet_name: String
@export var origin_planet_faction: Utility.FACTION

# --- Misison Type Specific Data ---
@export_group("Mission Specifics")
@export var container_target: ContainerData # Cargo name or Container item
@export var enemy_target_count: int = 0 # For Kill missions
@export var enemy_faction: Utility.FACTION
@export var cargo: String #
@export var bounty_name: String
@export var scanning_faction: Utility.FACTION # Contraband: faction whose patrols scan the hold
@export var contraband_detected: bool = false
## Objectives done - the player must open comms at the target system's starbase to finish.
@export var awaiting_turn_in: bool = false


## Completed by beaming cargo to target_planet_name via comms.
func is_delivery_type() -> bool:
	return type == MISSION_TYPE.DELIVERY or type == MISSION_TYPE.CONTRABAND


## HUD shows target_planet_name instead of the title.
func uses_target_planet() -> bool:
	return is_delivery_type() or type == MISSION_TYPE.ANALYZE
