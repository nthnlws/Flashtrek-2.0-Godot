extends Node

signal galaxyDataUpdated(galaxy_data:GalaxyData)

var galaxy_data: GalaxyData 
var current_system_data: SystemData
var target_system_data: SystemData

var spawn_options: Array[Area2D]
var factionShips: Array[FactionCharacter]
var neutralShips: Array[NeutralCharacter]
var missionShips: Array[MissionCharacter]
var levelWalls: Node2D
var planets: Array[Planet]
var sun: Sun
var player: Player
var starbases: Array[Starbase]
var containers: Array[ContainerPickup]

var rootLevel: RootLevel
var entry_coords:Vector2 # Position to spawn player after exiting warp


func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(update_system_data)
	SignalBus.level_loaded.connect(func(level): rootLevel = level)


func create_or_load_galaxy(slot:int) -> void:
	# Load save slot from save data
	if SaveManager.save_slot_exists(slot):
		#print_debug('Loaded slot %s data' % slot)
		galaxy_data = SaveManager.load_galaxy(slot)
	
	# No save data, generate new from scratch
	else: 
		galaxy_data = GalaxyData.generate_galaxy_data()
		SaveManager.save_galaxy(slot, galaxy_data)
		galaxy_data.current_system = galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Solarus)
		#print_debug('Saved newly created galaxy data to slot %s' % slot)
	galaxyDataUpdated.emit(galaxy_data)


func update_system_data() -> void:
	current_system_data = galaxy_data.get_system(target_system_data.system_index)
	target_system_data = null
