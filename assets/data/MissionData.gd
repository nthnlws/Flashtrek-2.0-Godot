# mission_data.gd
class_name MissionData
extends Resource

enum MISSION_TYPE { DELIVERY, CONTAINER, KILL_FACTION, ESCORT, ANALYSIS }

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

# --- Location Data ---
@export_group("Target Location")
@export var target_system: SystemData
@export var target_planet_name: String # Optional

# --- Specific Data (Can be used generically or subclassed) ---
@export_group("Mission Specifics")
@export var container_target: ContainerData # Cargo name or Container item
@export var enemy_target_count: int = 0 # For Kill missions
@export var enemy_faction: Utility.FACTION # For Kill missions
@export var cargo: String # 
