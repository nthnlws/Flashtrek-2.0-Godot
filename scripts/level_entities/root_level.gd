extends Node

signal level_loaded
signal system_data_updated(system_data: SystemData)

@export_category("Level Objects")
const LEVEL_BORDERS: PackedScene = preload("uid://bk5rb0wdhnfkm")
const PLANET: PackedScene = preload("uid://cjwf6ulibdpvr")
const STARBASE: PackedScene = preload("uid://oexei8cmm0yk")
const PLAYER_SPAWN_AREA: PackedScene = preload("uid://bxpqhkwbma8la")
const SUN: PackedScene = preload("uid://be1sbec7mtn51")
const FACTION_CHARACTER: PackedScene = preload("uid://c8tsyg40o4m7h")
const NEUTRAL_CHARACTER: PackedScene = preload("uid://crsud8w51n07n")
const MISSION_CHARACTER: PackedScene = preload("uid://c0vl8rhh5rl22")
const PLAYER: PackedScene = preload("uid://1wnfmblulhx0")
const upgrade_item: PackedScene = preload("uid://berjp6uasq671")

@onready var pickup_folder: Node = $item_pickups
@onready var level_folder: Node = $level_objects
@onready var ship_folder: Node = $ship_folder
@onready var component_folder: Node = $ComponentFolder

func _ready() -> void:
	#TODO: Remove force volume mute
	#var MAIN_BUS_ID: int = AudioServer.get_bus_index("Master")
	#AudioServer.set_bus_volume_db(MAIN_BUS_ID, linear_to_db(0.0))
	
	initialize_spawn_system()
	_connect_signals()


func _connect_signals() -> void:
	SignalBus.galaxy_warp_finished.connect(change_system)
	SignalBus.playerDied.connect(_handle_player_death)
	SignalBus.spawnLoot.connect(spawn_loot)
	SignalBus.triggerGalaxyWarp.connect(save_ship_data)
	SignalBus.spawnShip.connect(spawn_faction_ship)
	SignalBus.factionShipDied.connect(remove_faction_ship_data)
	SignalBus.neutralShipDied.connect(remove_neutral_ship_data)


func initialize_spawn_system() -> void:
	var spawn_system: SystemData = LevelManager.galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Solarus)
	if LevelManager.galaxy_data.current_system:
		spawn_system = LevelManager.galaxy_data.current_system
	change_system(spawn_system)
	spawn_player()
	
	level_loaded.emit()


func _build_components() -> void:
	for type:SystemData.SystemComponentType in LevelManager.current_system_data.active_components.keys():
		if LevelManager.current_system_data.component_map.has(type):
			var component_scene: PackedScene = LevelManager.current_system_data.component_map[type]
			var component_instance: SystemComponent = component_scene.instantiate() as SystemComponent
			
			# Component life cycle follows parent planet
			component_folder.add_child(component_instance)
			
			# Initialize with data and planet reference
			var mission_data:MissionData = LevelManager.current_system_data.active_components.get(type)
			component_instance.initialize_component(LevelManager.current_system_data, mission_data)
			
			print("System %s: Spawned component %s" % [LevelManager.current_system_data.system_name, SystemData.SystemComponentType.keys()[type]])
		else: printerr("No component type %s found in SystemData component_map dict" % SystemData.SystemComponentType.keys()[type])


func spawn_player() -> void:
	var init_player: Player = PLAYER.instantiate()
	level_folder.add_child(init_player)
	init_player.global_position = get_spawn_position()
	LevelManager.player = init_player


func change_system(new_system_data: SystemData) -> void:
	LevelManager.current_system_data = new_system_data
	LevelManager.galaxy_data.current_system = new_system_data
	cleanup_old_system()
	
	instantiate_new_system_nodes()
	sync_ships_to_data()
	sync_sun_to_data()
	
	_build_components()
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


func spawn_mission_ship(ship_type: Utility.SHIP_TYPES, position: Vector2, is_hostile: bool = false) -> MissionCharacter:
	var mission_faction: MissionCharacter = MISSION_CHARACTER.instantiate()
	mission_faction.add_to_group("mission_ships")
	mission_faction.ship_type = ship_type
	mission_faction.global_position = position
	ship_folder.add_child(mission_faction)
	LevelManager.missionShips.append(mission_faction)

	return mission_faction


func instantiate_neutral_ship(ship_data: NeutralShipData) -> NeutralCharacter:
	var new_neutral: NeutralCharacter = NEUTRAL_CHARACTER.instantiate()
	new_neutral.add_to_group("neutral_ships")
	
	new_neutral.get_node("HealthComponent").hp_current = ship_data.current_hp
	new_neutral.get_node("HealthComponent").HP_max = ship_data.HP_max
	new_neutral.get_node("HealthComponent").SP_max = ship_data.SP_max
	new_neutral.get_node("HealthComponent").sp_current = ship_data.current_sp
	
	new_neutral.global_position = ship_data.world_position
	new_neutral.get_node("Shield").shieldActive = ship_data.shield_state
	new_neutral.ship_type = ship_data.ship_type
	new_neutral.ship_index = ship_data.ship_index
	
	return new_neutral


func instantiate_faction_ship(ship_data: FactionShipData) -> FactionCharacter:
	var new_faction: FactionCharacter = FACTION_CHARACTER.instantiate()
	new_faction.add_to_group("faction_ships")
	
	new_faction.get_node("HealthComponent").hp_current = ship_data.current_hp
	new_faction.get_node("HealthComponent").HP_max = ship_data.HP_max
	new_faction.get_node("HealthComponent").SP_max = ship_data.SP_max
	new_faction.get_node("HealthComponent").sp_current = ship_data.current_sp

	new_faction.global_position = ship_data.world_position
	new_faction.get_node("Shield").shieldActive = ship_data.shield_state
	new_faction.ship_type = ship_data.ship_type
	new_faction.difficulty_multiplier = ship_data.difficulty_multiplier
	new_faction.ship_index = ship_data.ship_index
	
	return new_faction


func instantiate_NPC_ships() -> void:
	for i: int in range(LevelManager.current_system_data.enemy_list.size()):
		var new_faction: FactionCharacter = instantiate_faction_ship(LevelManager.current_system_data.enemy_list[i])
		ship_folder.add_child(new_faction)
		LevelManager.factionShips.append(new_faction)
	
	for i: int in range(LevelManager.current_system_data.neutral_list.size()):
		var new_neutral: NeutralCharacter = instantiate_neutral_ship(LevelManager.current_system_data.neutral_list[i])
		ship_folder.add_child(new_neutral)
		LevelManager.neutralShips.append(new_neutral)


func sync_ships_to_data() -> void:
	if (LevelManager.neutralShips.size() != LevelManager.current_system_data.neutral_list.size()
		or LevelManager.factionShips.size() != LevelManager.current_system_data.enemy_list.size()):
			printerr("Data size and spawned ship size mismatch, check LevelManager data")
	# Neutral Ships
	for i: int in range(LevelManager.neutralShips.size()):
		var data: NeutralShipData = LevelManager.current_system_data.neutral_list[i]
		var ship: NeutralCharacter = LevelManager.neutralShips[i]
		ship.global_position = data.world_position
		ship.health_component.hp_current = data.current_hp
		ship.health_component.sp_current = data.current_sp
		ship.health_component.SP_max = data.SP_max
		ship.health_component.HP_max = data.HP_max
		ship.shield.shieldActive = data.shield_state
		ship.ship_index = data.ship_index
	
	# Faction Ships
	for i: int in range(LevelManager.factionShips.size()):
		var data: FactionShipData = LevelManager.current_system_data.enemy_list[i]
		var ship: FactionCharacter = LevelManager.factionShips[i]
		ship.global_position = data.world_position
		ship.health_component.hp_current = data.current_hp
		ship.health_component.sp_current = data.current_sp
		ship.health_component.SP_max = data.SP_max
		ship.health_component.HP_max = data.HP_max
		ship.shield.shieldActive = data.shield_state
		ship.ship_index = data.ship_index


func sync_sun_to_data() -> void:
	LevelManager.sun.global_position = LevelManager.current_system_data.sun_data.world_position
	LevelManager.sun.set_frame(LevelManager.current_system_data.sun_data.frame)


func save_ship_data() -> void:
	var neutral_data: Array[NeutralShipData] = LevelManager.current_system_data.neutral_list
	var enemy_data: Array[FactionShipData] = LevelManager.current_system_data.enemy_list
	
	if (neutral_data.size() != LevelManager.neutralShips.size() or enemy_data.size() != LevelManager.factionShips.size()):
		printerr("Array size mismatch between SystemData and LevelManager ship arrays.")
		return

	for i: int in range(LevelManager.neutralShips.size()):
		var ship: NeutralCharacter = LevelManager.neutralShips[i]
		var data: NeutralShipData = neutral_data[i]
		
		data.world_position = ship.global_position
		data.current_hp = ship.health_component.hp_current
		data.current_sp = ship.health_component.sp_current
		data.shield_state = ship.shield.shieldActive
		
	for i: int in range(LevelManager.factionShips.size()):
		var ship: FactionCharacter = LevelManager.factionShips[i]
		var data: FactionShipData = enemy_data[i]
		
		data.world_position = ship.global_position
		data.current_hp = ship.health_component.hp_current
		data.current_sp = ship.health_component.sp_current
		data.shield_state = ship.shield.shieldActive
		
	system_data_updated.emit(LevelManager.current_system_data)


func instantiate_new_system_nodes() -> void:
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
	
	for i: int in LevelManager.current_system_data.planet_data.size(): # Spawn required planets
		var init_planet: Node2D = PLANET.instantiate()
		init_planet.planet_data = LevelManager.current_system_data.planet_data[i]
		level_folder.add_child(init_planet)
		LevelManager.planets.append(init_planet)
	
	instantiate_NPC_ships()


func get_spawn_position() -> Vector2:
	return LevelManager.spawn_options.pick_random().global_position


func remove_faction_ship_data(ship: FactionCharacter) -> void:
	LevelManager.factionShips.erase(ship)
	LevelManager.current_system_data.remove_faction_ship_data(ship.ship_index)

func remove_neutral_ship_data(ship: NeutralCharacter) -> void:
	LevelManager.neutralShips.erase(ship)
	LevelManager.current_system_data.remove_neutral_ship_data(ship.ship_index)


func spawn_faction_ship(ship_type: Utility.SHIP_TYPES) -> void:
	var position: Vector2 = LevelManager.player.global_position
	var faction_ship: FactionCharacter = FACTION_CHARACTER.instantiate()
	faction_ship.add_to_group("faction_ships")
	faction_ship.ship_type = ship_type
	LevelManager.ship_folder.add_child(faction_ship)
	
	faction_ship.global_position = position
	faction_ship.hp_max = faction_ship.hp_max * LevelManager.current_system_data.system_difficulty_mult
	faction_ship.damage_mult = faction_ship.damage_mult * LevelManager.current_system_data.system_difficulty_mult
	faction_ship.name = "ManualFactionShip"


func spawn_loot(type: UpgradePickup.MODULE_TYPES, position: Vector2, number: int = 1) -> void:
	for i in number:
		var new_drop: UpgradePickup = upgrade_item.instantiate()
		new_drop.global_position = position
		new_drop.scale = Vector2(1.25, 1.25)
		new_drop.upgrade_type = type
		pickup_folder.call_deferred("add_child", new_drop)


func _handle_player_death() -> void:
	var home_system: SystemData = Utility.get_faction_home_system(LevelManager.player.faction)
	LevelManager.player.global_position = get_spawn_position()
	
	# Do not change system if died in home system
	if LevelManager.current_system_data != home_system:
		change_system(home_system)
