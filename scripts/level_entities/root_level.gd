extends Node
class_name RootLevel

signal system_data_updated(system_data: SystemData)

@export_category("Level Objects")
const LEVEL_BORDERS: PackedScene = preload("uid://bk5rb0wdhnfkm")
const PLANET: PackedScene = preload("uid://cjwf6ulibdpvr")
const STARBASE: PackedScene = preload("uid://oexei8cmm0yk")
const PLAYER_SPAWN_AREA: PackedScene = preload("uid://bxpqhkwbma8la")
const SUN: PackedScene = preload("uid://be1sbec7mtn51")
@onready var FACTION_CHARACTER: PackedScene = load("res://scenes/level_entities/FactionCharacter.tscn")
@onready var NEUTRAL_CHARACTER: PackedScene = load("res://scenes/level_entities/NeutralCharacter.tscn")
@onready var MISSION_CHARACTER: PackedScene = load("res://scenes/level_entities/MissionCharacter.tscn")
const PLAYER: PackedScene = preload("uid://1wnfmblulhx0")
const upgrade_item: PackedScene = preload("uid://berjp6uasq671")

@onready var pickup_folder: Node = $item_pickups
@onready var level_folder: Node = $level_objects
@onready var ship_folder: Node = $ship_folder
@onready var system_components: Node = $SystemComponentManager


func _ready() -> void:
	initialize_spawn_system()
	_connect_signals()


func _connect_signals() -> void:
	SignalBus.galaxy_warp_finished.connect(change_system)
	SignalBus.playerDied.connect(_handle_player_death)
	SignalBus.spawnLoot.connect(spawn_loot)
	SignalBus.triggerGalaxyWarp.connect(save_ship_data)
	SignalBus.factionShipDied.connect(remove_faction_ship_data)
	SignalBus.neutralShipDied.connect(remove_neutral_ship_data)


func initialize_spawn_system() -> void:
	var spawn_system: SystemData = LevelManager.galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Solarus)
	if LevelManager.galaxy_data.current_system:
		spawn_system = LevelManager.galaxy_data.current_system
	change_system(spawn_system)
	spawn_player()
	
	SignalBus.level_loaded.emit(self)


func spawn_player() -> void:
	var init_player: Player = PLAYER.instantiate()
	var base_info: BaseShipInfo = Utility.get_ship_stats(Utility.starting_ship)
	var scaled_stats: ShipState = ShipState.get_player_scaled_stats(0, 6, base_info)
	init_player.ship_stats = scaled_stats
	level_folder.add_child(init_player)
	init_player.global_position = get_spawn_position()
	LevelManager.player = init_player


func change_system(new_system_data: SystemData) -> void:
	LevelManager.current_system_data = new_system_data
	LevelManager.galaxy_data.current_system = new_system_data
	cleanup_old_system()
	
	instantiate_new_system_nodes(new_system_data)
	sync_ships_to_data()
	sync_sun_to_data(new_system_data.sun_data)
	
	#TODO spawn new components
	save_ship_data()
	
	#print("changing to system: %s" % new_system_data.system_name)

	SignalBus.system_changed.emit(new_system_data)
	AudioManager.play_music(false, new_system_data.faction)


func cleanup_old_system() -> void:
	# Cleanup Arrays
	for array in [LevelManager.factionShips, LevelManager.missionShips, LevelManager.neutralShips, LevelManager.spawn_options, LevelManager.planets, LevelManager.starbases]:
		array.clear()
	
	# Cleanup Objects
	var ship_objects = ship_folder.get_children(true)
	var pickup_objects = pickup_folder.get_children(true)
	var level_objects = level_folder.get_children(true)
	
	for obj: Node2D in ship_objects + pickup_objects + level_objects:
		if !obj.is_in_group("player"):
		#print("Deleting %s" % obj.name)
			obj.free()


func spawn_mission_ship(ship_data: ShipState) -> MissionCharacter:
	var mission_faction: MissionCharacter = MISSION_CHARACTER.instantiate()
	mission_faction.add_to_group("mission_ships")
	mission_faction.global_position = ship_data.save_position
	ship_folder.add_child(mission_faction)
	LevelManager.missionShips.append(mission_faction)

	return mission_faction


func instantiate_neutral_ship(ship_data: ShipState) -> NeutralCharacter:
	var new_neutral: NeutralCharacter = NEUTRAL_CHARACTER.instantiate()
	new_neutral.ship_stats = ship_data
	new_neutral.global_position = ship_data.save_position
	new_neutral.add_to_group("neutral_ships")
	return new_neutral


func instantiate_faction_ship(ship_data: ShipState) -> FactionCharacter:
	var new_faction: FactionCharacter = FACTION_CHARACTER.instantiate()
	new_faction.ship_stats = ship_data
	new_faction.global_position = ship_data.save_position
	new_faction.add_to_group("faction_ships")
	return new_faction


func instantiate_NPC_ships(system_data: SystemData) -> void:
	var i: int = 1
	for ship: ShipState in system_data.enemy_list:
		var new_faction: FactionCharacter = instantiate_faction_ship(ship)
		new_faction.name = "FactionCharacter%s" % i
		ship_folder.add_child(new_faction)
		LevelManager.factionShips.append(new_faction)
		i += 1
	
	i = 1
	for ship:ShipState in system_data.neutral_list:
		var new_neutral: NeutralCharacter = instantiate_neutral_ship(ship)
		new_neutral.name = "NeutralCharacter%s" % i
		ship_folder.add_child(new_neutral)
		LevelManager.neutralShips.append(new_neutral)
		i += 1


func sync_ships_to_data() -> void:
	if (LevelManager.neutralShips.size() != LevelManager.current_system_data.neutral_list.size()
		or LevelManager.factionShips.size() != LevelManager.current_system_data.enemy_list.size()):
			printerr("Data size and spawned ship size mismatch, check LevelManager data")
	# Neutral Ships
	for i: int in range(LevelManager.neutralShips.size()):
		var data: ShipState = LevelManager.current_system_data.neutral_list[i]
		var ship: NeutralCharacter = LevelManager.neutralShips[i]
		ship.ship_stats = data
		ship.sync_ship_to_resource()
	
	# Faction Ships
	for i: int in range(LevelManager.factionShips.size()):
		var data: ShipState = LevelManager.current_system_data.enemy_list[i]
		var ship: FactionCharacter = LevelManager.factionShips[i]
		ship.ship_stats = data
		ship.sync_ship_to_resource()


func sync_sun_to_data(sun_data: SunData) -> void:
	LevelManager.sun.global_position = sun_data.world_position
	LevelManager.sun.set_frame(sun_data.frame)


func save_ship_data() -> void:
	var neutral_data: Array[ShipState] = LevelManager.current_system_data.neutral_list
	var enemy_data: Array[ShipState] = LevelManager.current_system_data.enemy_list
	
	if (neutral_data.size() != LevelManager.neutralShips.size() or enemy_data.size() != LevelManager.factionShips.size()):
		printerr("Array size mismatch between SystemData and LevelManager ship arrays.")
		return

	for i: int in range(LevelManager.neutralShips.size()):
		var ship: NeutralCharacter = LevelManager.neutralShips[i]
		var data: ShipState = neutral_data[i]
		
		data.save_position = ship.global_position
		data.save_health = ship.health_component.getCurrentHP()
		data.save_shield_health = ship.health_component.getCurrentSP()
		data.save_shield_status = ship.shield.shieldActive
		
	for i: int in range(LevelManager.factionShips.size()):
		var ship: FactionCharacter = LevelManager.factionShips[i]
		var data: ShipState = enemy_data[i]
		
		data.save_position = ship.global_position
		data.save_health = ship.health_component.getCurrentHP()
		data.save_shield_health = ship.health_component.getCurrentSP()
		data.save_shield_status = ship.shield.shieldActive
		
	system_data_updated.emit(LevelManager.current_system_data)


func instantiate_new_system_nodes(system_data: SystemData) -> void:
	var init_border: Node2D = LEVEL_BORDERS.instantiate()
	level_folder.add_child(init_border)
	LevelManager.levelWalls = init_border

	var init_sun: Node2D = SUN.instantiate()
	level_folder.add_child(init_sun)
	LevelManager.sun = init_sun
	
	var init_starbase: Node2D = STARBASE.instantiate()
	level_folder.add_child(init_starbase)
	init_starbase.global_position = Vector2.ZERO
	LevelManager.starbases.append(init_starbase)
	
	var init_spawn: Area2D = PLAYER_SPAWN_AREA.instantiate()
	level_folder.add_child(init_spawn)
	LevelManager.spawn_options.append(init_spawn)
	
	for i: int in system_data.planet_data.size(): # Spawn required planets
		var init_planet: Node2D = PLANET.instantiate()
		init_planet.planet_data = LevelManager.current_system_data.planet_data[i]
		level_folder.add_child(init_planet)
		LevelManager.planets.append(init_planet)
	
	instantiate_NPC_ships(system_data)


func get_spawn_position() -> Vector2:
	return LevelManager.spawn_options.pick_random().global_position


func remove_faction_ship_data(ship: FactionCharacter) -> void:
	LevelManager.factionShips.erase(ship)
	LevelManager.current_system_data.remove_faction_ship_data(ship.ship_stats)

func remove_neutral_ship_data(ship: NeutralCharacter) -> void:
	LevelManager.neutralShips.erase(ship)
	LevelManager.current_system_data.remove_neutral_ship_data(ship.ship_stats)


func spawn_loot(type: UpgradePickup.MODULE_TYPES, position: Vector2, number: int = 1) -> void:
	for i in number:
		var new_drop: UpgradePickup = upgrade_item.instantiate()
		new_drop.global_position = position
		new_drop.scale = Vector2(1.25, 1.25)
		new_drop.upgrade_type = type
		pickup_folder.call_deferred("add_child", new_drop)


func _handle_player_death() -> void:
	var home_system: SystemData = Utility.get_faction_home_system(LevelManager.player.ship_stats.current_faction)
	LevelManager.player.global_position = get_spawn_position()
	
	# Do not change system if died in home system
	if LevelManager.current_system_data != home_system:
		change_system(home_system)
