extends Node

var spawn_options: Array[Area2D]
var factionShips: Array[FactionCharacter]
var neutralShips: Array[NeutralCharacter]
var levelWalls: Node2D
var planets: Array[Node2D]
var sun: Sun
var player: Player
var starbases: Array[Node2D]
var containers: Array[ContainerPickup]
var mission_characters: Array[MissionCharacter]


@export_category("Level Objects")
const LEVEL_BORDERS = preload("uid://bk5rb0wdhnfkm")
const PLANET = preload("uid://cjwf6ulibdpvr")
const STARBASE = preload("uid://oexei8cmm0yk")
const PLAYER_SPAWN_AREA = preload("uid://bxpqhkwbma8la")
const SUN = preload("uid://be1sbec7mtn51")
const FACTION_CHARACTER = preload("uid://c8tsyg40o4m7h")
const NEUTRAL_CHARACTER = preload("uid://crsud8w51n07n")
const PLAYER = preload("uid://1wnfmblulhx0")

var upgrade_item: PackedScene = preload("uid://berjp6uasq671")
var pickups: Node
var ship_folder: Node
var level_folder: Node
var pickup_folder: Node
var minimap: Control

var galaxy_data: GalaxyData 
var current_system_data: SystemData
var target_system_data: SystemData # Set by galaxy map scene upon system selection

var entry_coords:Vector2 # Position to spawn player after exiting warp


func _ready() -> void:
	_connect_signals()


func create_or_load_galaxy(slot:int) -> void:
	# Create or load galaxy from save slot
	if SaveManager.save_slot_exists(slot):
		#print_debug('Loaded slot %s data' % slot)
		galaxy_data = SaveManager.load_galaxy(slot)
	else:
		galaxy_data = GalaxyData.generate_galaxy_data()
		SaveManager.save_galaxy(slot, galaxy_data)
		#print_debug('Saved newly created galaxy data to slot %s' % slot)
	current_system_data = galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Solarus)


func _connect_signals() -> void:
	SignalBus.galaxy_warp_finished.connect(change_system)
	SignalBus.entering_galaxy_warp.connect(update_system_data)
	SignalBus.playerDied.connect(_handle_player_death)
	SignalBus.spawnLoot.connect(spawn_loot)
	SignalBus.triggerGalaxyWarp.connect(save_ship_data)
	SignalBus.spawnShip.connect(spawn_faction_ship)
	SignalBus.factionShipDied.connect(remove_faction_ship_data)
	SignalBus.neutralShipDied.connect(remove_neutral_ship_data)


func _handle_player_death() -> void:
	var home_system:SystemData = galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Solarus)
	change_system(home_system)
	player.global_position = get_spawn_position()
	minimap.create_minimap_objects()


func on_level_loaded() -> void:
	var default_system: SystemData = galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Solarus)
	Utility.current_gamestate = Utility.GAMESTATE.SYSTEM
	
	# Node paths
	pickups = get_node("/root/Game/Level/item_pickups") 
	ship_folder = get_node("/root/Game/Level/ship_folder")
	pickup_folder = get_node("/root/Game/Level/item_pickups")
	level_folder = get_node("/root/Game/Level/level_objects")
	minimap = get_node("/root/Game/HUD_layer/MiniMap")
	
	# System setup
	instantiate_new_system_nodes(default_system) # Initial creation of all level nodes
	change_system(default_system)
	save_ship_data(default_system)
	minimap.create_minimap_objects() # Refresh minimap objects
	
	SignalBus.galaxyDataUpdated.emit(galaxy_data)


func on_level_unloaded() -> void:
	for array in [factionShips, neutralShips, spawn_options, planets, starbases]:
		array.clear()


func update_system_data() -> void:
	current_system_data = galaxy_data.get_system(target_system_data.system_index)
	target_system_data = null


func spawn_faction_ship(ship_type:Utility.SHIP_TYPES) -> void:
	var position: Vector2 = player.global_position
	var faction_ship:FactionCharacter = FACTION_CHARACTER.instantiate()
	faction_ship.add_to_group("faction_ships")
	faction_ship.ship_type = ship_type
	factionShips.append(faction_ship)
	ship_folder.add_child(faction_ship)
	
	faction_ship.global_position = position
	faction_ship.hp_max = faction_ship.hp_max * current_system_data.system_difficulty_mult
	faction_ship.damage_mult = faction_ship.damage_mult * current_system_data.system_difficulty_mult
	faction_ship.name = "ManualFactionShip"


func spawn_loot(type:UpgradePickup.MODULE_TYPES, position:Vector2, number:int) -> void:
	for i in number:
		var new_drop:UpgradePickup = upgrade_item.instantiate()
		new_drop.global_position = position
		new_drop.scale = Vector2(1.25, 1.25)
		new_drop.upgrade_type = type
		pickups.call_deferred("add_child",new_drop)


func change_system(system_data:SystemData) -> void:
	current_system_data = system_data # Update current SystemData
	#print('Changing system to %s' % system_data.system_name)
	
	cleanup_old_system()
	
	# Create new NPCs
	instantiate_NPC_ships(system_data)
	instantiate_planets(system_data)
	
	# Data sync functions
	sync_sun_to_data(system_data.sun_data)
	sync_containers_to_data(system_data.mission_containers)
	
	SignalBus.system_changed.emit(system_data)


func instantiate_neutral_ship(ship_data:NeutralData) -> NeutralCharacter:
	var new_neutral:NeutralCharacter = NEUTRAL_CHARACTER.instantiate()
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


func instantiate_faction_ship(ship_data:FactionShipData) -> FactionCharacter:
	var new_faction:FactionCharacter = FACTION_CHARACTER.instantiate()
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


func instantiate_NPC_ships(system_data:SystemData) -> void:
	for i:int in range(system_data.enemy_list.size()):
		var new_faction:FactionCharacter = instantiate_faction_ship(system_data.enemy_list[i])
		ship_folder.add_child(new_faction)
		factionShips.append(new_faction)
	
	for i:int in range(system_data.neutral_list.size()):
		var new_neutral:NeutralCharacter = instantiate_neutral_ship(system_data.neutral_list[i])
		ship_folder.add_child(new_neutral)
		neutralShips.append(new_neutral)


func sync_ships_to_data(system_data:SystemData) -> void:
	if (neutralShips.size() != system_data.neutral_list.size()
		or factionShips.size() != system_data.enemy_list.size()):
			printerr("Data size and spawned ship size mismatch, check LevelManager data")
	# Neutral Ships
	for i:int in range(neutralShips.size()):
		var data:NeutralData = system_data.neutral_list[i]
		var ship:NeutralCharacter = neutralShips[i]
		ship.global_position = data.world_position
		ship.health_component.hp_current = data.current_hp
		ship.health_component.sp_current = data.current_sp
		ship.health_component.SP_max = data.SP_max
		ship.health_component.HP_max = data.HP_max
		ship.shield.shieldActive = data.shield_state
		ship.ship_index = data.ship_index
	
	# Faction Ships
	for i:int in range(factionShips.size()):
		var data:FactionShipData = system_data.enemy_list[i]
		var ship:FactionCharacter = neutralShips[i]
		ship.global_position = data.world_position
		ship.health_component.hp_current = data.current_hp
		ship.health_component.sp_current = data.current_sp
		ship.health_component.SP_max = data.SP_max
		ship.health_component.HP_max = data.HP_max
		ship.shield.shieldActive = data.shield_state
		ship.ship_index = data.ship_index


func sync_sun_to_data(sun_data:SunData) -> void:
	sun.global_position = sun_data.world_position
	sun.set_frame(sun_data.frame)


func sync_containers_to_data(mission_containers:Array[ContainerData]) -> void:
	# Cleanup old containers
	for container:ContainerPickup in containers:
		if container:
			container.queue_free()
	
	# Spawn new containers	
	if !mission_containers.is_empty():
		var CONTAINER_SCENE:PackedScene = preload("uid://dess4qrmx6vve")
		for container:ContainerData in mission_containers:
			var new_container:ContainerPickup = CONTAINER_SCENE.instantiate()
			new_container.container_data = container
			pickup_folder.add_child(new_container)
			containers.append(new_container)


func save_ship_data(current_sys_data: SystemData) -> void:
	var neutral_data: Array[NeutralData] = current_sys_data.neutral_list
	var enemy_data: Array[FactionShipData] = current_sys_data.enemy_list
	
	if (neutral_data.size() != neutralShips.size() or enemy_data.size() != factionShips.size()):
		printerr("Array size mismatch between SystemData and LevelManager ship arrays.")
		return

	for i: int in range(neutralShips.size()):
		var ship: NeutralCharacter = neutralShips[i]
		var data: NeutralData = neutral_data[i]
		
		data.world_position = ship.global_position
		data.current_hp = ship.health_component.hp_current
		data.current_sp = ship.health_component.sp_current
		data.shield_state = ship.shield.shieldActive
		
	for i: int in range(factionShips.size()):
		var ship: FactionCharacter = factionShips[i]
		var data: FactionShipData = enemy_data[i]
		
		data.world_position = ship.global_position
		data.current_hp = ship.health_component.hp_current
		data.current_sp = ship.health_component.sp_current
		data.shield_state = ship.shield.shieldActive
		
	SignalBus.updateGalaxyData.emit(galaxy_data)


func cleanup_old_system() -> void:
	var old_upgrade_drops:Array[Node] = get_tree().get_nodes_in_group("upgrade_drop")
	for drop:Area2D in old_upgrade_drops: # Delete all upgrade drops
		drop.queue_free()
	
	for ship:CharacterBody2D in neutralShips + factionShips:
		ship.queue_free() # Delete all old ships
	
	for container:ContainerPickup in containers:
		if container:
			container.queue_free()
	
	for planet:Planet in planets:
		planet.queue_free()
	
	planets.clear()
	factionShips.clear()
	neutralShips.clear()


func instantiate_planets(system_data:SystemData) -> void:
	for i:int in system_data.planet_data.size(): # Spawn required planets
		var init_planet: Node2D = PLANET.instantiate()
		init_planet.planet_data = system_data.planet_data[i]
		level_folder.add_child(init_planet)
		planets.append(init_planet)


func instantiate_new_system_nodes(system_data: SystemData) -> void:
	var init_border: Node2D = LEVEL_BORDERS.instantiate()
	level_folder.add_child(init_border)
	levelWalls = init_border

	var init_sun: Node2D = SUN.instantiate()
	level_folder.add_child(init_sun)
	sun = init_sun
	
	var init_starbase: Node2D = STARBASE.instantiate()
	level_folder.add_child(init_starbase)
	init_starbase.global_position = Vector2.ZERO
	starbases.append(init_starbase)
	
	var init_spawn: Area2D = PLAYER_SPAWN_AREA.instantiate()
	level_folder.add_child(init_spawn)
	spawn_options.append(init_spawn)
	
	var init_player: Player = PLAYER.instantiate()
	level_folder.add_child(init_player)
	init_player.global_position = get_spawn_position()
	player = init_player


func get_spawn_position() -> Vector2:
	return spawn_options.pick_random().global_position


func remove_faction_ship_data(ship:FactionCharacter) -> void:
	factionShips.erase(ship)
	current_system_data.remove_faction_ship_data(ship.ship_index)


func remove_neutral_ship_data(ship:NeutralCharacter) -> void:
	neutralShips.erase(ship)
	current_system_data.remove_neutral_ship_data(ship.ship_index)
