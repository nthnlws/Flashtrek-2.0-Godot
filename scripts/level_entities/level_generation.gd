extends Node

@export_category("Level Objects")
@export var levelBorders: PackedScene
@export var Planet: PackedScene
@export var Starbase: PackedScene
@export var PlayerSpawnArea: PackedScene
@export var Sun: PackedScene
@export var FactionShip: PackedScene
@export var NeutralShip: PackedScene
@export var Player: PackedScene

@export_category("Items")
@export var item_pickup: PackedScene

@onready var game: Node2D = $".."
@onready var pickups: Node = $item_pickups
@onready var ship_folder: Node = $ship_folder


func _ready() -> void:
	SignalBus.galaxy_warp_finished.connect(_change_system)
	SignalBus.playerDied.connect(_change_system.bind("Solarus"))
	SignalBus.spawnLoot.connect(spawn_loot)
	SignalBus.triggerGalaxyWarp.connect(save_ship_data.unbind(1))
	SignalBus.spawnShip.connect(spawn_faction_ship)
	
	instantiate_new_system_nodes() # Init spawn for all level nodes
	get_parent().generate_system_info() # Generate info for all systems
	_change_system("Solarus") # Spawn planets and move to JSON data location
	
	save_ship_data()


func spawn_faction_ship(ship_type:Utility.SHIP_TYPES) -> void:
	var system_data:Dictionary = LevelData.all_systems_data[Navigation.currentSystem]
	var position: Vector2 = LevelData.player.global_position
	var faction_ship:FactionCharacter = FactionShip.instantiate()
	faction_ship.add_to_group("level_nodes")
	faction_ship.add_to_group("enemy_ships")
	faction_ship.ship_type = ship_type
	faction_ship.global_position = position
	LevelData.enemyShips.append(faction_ship)
	ship_folder.add_child(faction_ship)

	faction_ship.hp_max = faction_ship.hp_max * system_data["ship_health_mult"]
	faction_ship.damage_mult = faction_ship.damage_mult * system_data["enemy_damage_mult"]
	faction_ship.name = "ManualFactionShip"
	
	
	
func spawn_loot(type:UpgradePickup.MODULE_TYPES, position:Vector2, number:int) -> void:
	for i in number:
		var new_drop:UpgradePickup = item_pickup.instantiate()
		new_drop.global_position = position
		new_drop.scale = Vector2(1.25, 1.25)
		new_drop.upgrade_type = type
		pickups.call_deferred("add_child",new_drop)


func _change_system(targetSystem:String) -> void:
	var sync_system:Dictionary = LevelData.all_systems_data[targetSystem]
	cleanup_old_system()
	
	sync_planets_to_dict(targetSystem)
	
	if not sync_system["enemies"].is_empty(): # Some enemy data already exists for system
		var num_enemies:int = min(sync_system["enemies"].size(), LevelData.planets.size())
		_instaniate_ships(num_enemies, sync_system)
	elif sync_system["neutrals_defeated"] == false: # System data empty and system not defeated, generating enemies
		_instaniate_ships(LevelData.planets.size(), sync_system)
		
	# --- Neutrals Logic ---
	if sync_system["neutrals"].is_empty():
		if sync_system["neutrals_defeated"] == true:
			#print("NEUTRALS: Dict is empty and they were already defeated. Doing nothing.")
			pass
		else:
			#print("NEUTRALS: Dict is empty, not yet defeated. Generating new positions.")
			generate_neutral_positions(LevelData.neutralShips)
	else:
		#print("NEUTRALS: Dict is NOT empty. Syncing existing data.")
		sync_neutral_to_dict(targetSystem, LevelData.neutralShips)

	# --- Enemies Logic ---
	if sync_system["enemies"].is_empty():
		if sync_system["enemies_defeated"] == true:
			#print("ENEMIES: Dict is empty and they were already defeated. Doing nothing.")
			pass
		else:
			#print("ENEMIES: Dict is empty, not yet defeated. Generating new positions.")
			generate_enemy_positions(LevelData.enemyShips)
	else:
		#print("ENEMIES: Dict is NOT empty. Syncing existing data.")
		sync_enemies_to_dict(targetSystem, LevelData.enemyShips)
	
	save_ship_data()
	sync_sun_to_dict(targetSystem)

	%MiniMap.create_minimap_objects() # Refresh minimap objects


func _instaniate_ships(PLANET_COUNT:int, system_data:Dictionary) -> void:
	for i:int in range(PLANET_COUNT):
		var faction_ship:FactionCharacter = FactionShip.instantiate()
		faction_ship.add_to_group("level_nodes")
		faction_ship.add_to_group("enemy_ships")
		
		faction_ship.ship_type = _get_faction_ship(system_data)
		LevelData.enemyShips.append(faction_ship)
		ship_folder.add_child(faction_ship)
		

		faction_ship.hp_max = faction_ship.hp_max * system_data["ship_health_mult"]
		faction_ship.damage_mult = faction_ship.damage_mult * system_data["enemy_damage_mult"]
		faction_ship.name = "Enemy_" + str(i)
	for i:int in range(PLANET_COUNT):
		var new_neutral:NeutralCharacter = NeutralShip.instantiate()
		new_neutral.add_to_group("level_nodes")
		new_neutral.add_to_group("neutral_ships")

		new_neutral.ship_type = _get_neutral_ship(system_data)
		LevelData.neutralShips.append(new_neutral)
		ship_folder.add_child(new_neutral)
		
		new_neutral.hp_max = new_neutral.hp_max * system_data["ship_health_mult"]
		new_neutral.name = "Neutral_" + str(i)


func _get_neutral_ship(system_data:Dictionary) -> Utility.SHIP_TYPES:
	var neutral_ship_array:Array[Utility.SHIP_TYPES] = [
		Utility.SHIP_TYPES.Merchantman,
		Utility.SHIP_TYPES.DKora_Marauder,
		Utility.SHIP_TYPES.Hideki_Class,
		Utility.SHIP_TYPES.Tellarite_Cruiser,
		Utility.SHIP_TYPES.Talarian_Freighter,
	]
	return neutral_ship_array.pick_random()


func _get_faction_ship(system_data:Dictionary) -> Utility.SHIP_TYPES:
	match system_data["faction"] as Utility.FACTION:
		Utility.FACTION.FEDERATION:
			return Utility.SHIP_TYPES.Ambassador_Class
		Utility.FACTION.KLINGON:
			return Utility.SHIP_TYPES.Brel_Class
		Utility.FACTION.ROMULAN:
			return Utility.SHIP_TYPES.Dderidex_Class
		Utility.FACTION.NEUTRAL:
			return Utility.SHIP_TYPES.JemHadar
		_:
			push_error("Unknown faction type %s" % system_data["faction"])
			return Utility.SHIP_TYPES.Merchantman


func generate_enemy_positions(enemy_ships:Array[FactionCharacter]) -> void:
	var planets = LevelData.planets
	var max_spawn_distance: int = 1500
	var min_spawn_distance: int = 500
	var random_angle: float = randf_range(0, TAU)
	var spawn_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
	var spawn_position: Vector2 = Vector2.from_angle(random_angle) * spawn_distance
	
	if enemy_ships.size() != planets.size():
		push_error("Enemy ships and planets count mismatch! %s enemy ships and %s planets" % [enemy_ships.size(), planets.size()])
		return

	for e in enemy_ships.size():
		enemy_ships[e].global_position = planets[e].global_position + spawn_position


func generate_neutral_positions(neutral_ships:Array[NeutralCharacter]) -> void:
	var planets = LevelData.planets
	
	if neutral_ships.size() != planets.size():
		push_error("Neutral ships and planets count mismatch! %s neutral ships and %s planets" % [neutral_ships.size(), planets.size()])
		return
	
	for n in neutral_ships.size():
		# Set spawn distance between 20-80% from starbase to planet
		var random_fraction: float = clamp(randf(),0.2, 0.8)
		var spawn_pos: Vector2 = Vector2.ZERO.lerp(planets[n].global_position, random_fraction)

		neutral_ships[n].global_position = spawn_pos


func sync_neutral_to_dict(targetSystem:String, neutral_array:Array[NeutralCharacter]) -> void:
	var sync_system:Dictionary = LevelData.all_systems_data[targetSystem]
	for n in neutral_array:
		var ship_data:Dictionary = sync_system["neutrals"][str(n.name)]
		n.global_position = ship_data["position"]
		n.shield_on = ship_data["shield_state"]
		n.moveTarget = ship_data["movement_target"]
		n.hp_max = ship_data["max_hp"]
		n.shield.sp_max = ship_data["max_sp"]
		n.hp_current = ship_data["current_hp"]
		n.shield.sp_current = ship_data["current_sp"]


func sync_enemies_to_dict(targetSystem:String, enemy_array:Array[FactionCharacter]) -> void:
	var sync_system:Dictionary = LevelData.all_systems_data[targetSystem]
	for e in enemy_array:
		var ship_data:Dictionary = sync_system["enemies"][str(e.name)]
		if ship_data:
			e.global_position = ship_data["position"]
			e.shield_on = ship_data["shield_state"]
			e.moveTarget = ship_data["movement_target"]
			e.hp_max = ship_data["max_hp"]
			e.shield.sp_max = ship_data["max_sp"]
			e.hp_current = ship_data["current_hp"]
			e.shield.sp_current = ship_data["current_sp"]
		else:
			push_error("Enemy %s not found in system data" % e.name)

func sync_sun_to_dict(targetSystem:String) -> void:
	var sun_data: Dictionary = LevelData.all_systems_data[targetSystem]["sun_data"]
	var sun: Node2D = LevelData.suns[0]
	sun.global_position.x = sun_data.x
	sun.global_position.y = sun_data.y
	sun.sprite.frame = sun_data.frame


func sync_planets_to_dict(targetSystem:String) -> void:
	# Combining all planets into temp array for new system spawning
	var all_planets: Array = LevelData.planets + LevelData.unused_planets
	# Clear old arrays
	LevelData.planets.clear()
	LevelData.unused_planets.clear()
	
	var planet_data: Array = LevelData.all_systems_data[targetSystem]["planet_data"]
	for p in planet_data.size(): # Sets planets to JSON data
		all_planets[p].global_position.x = planet_data[p].x
		all_planets[p].global_position.y = planet_data[p].y
		all_planets[p].sprite.frame = planet_data[p].frame
		all_planets[p].name = planet_data[p].name
		all_planets[p].set_label(planet_data[p].name)
		LevelData.planets.append(all_planets[p])
		LevelData.planets[p].planetFaction = LevelData.all_systems_data[targetSystem]["faction"]

	if planet_data.size() < 6:
		for extra in 6 - planet_data.size():
			LevelData.unused_planets.append(all_planets.pop_back())
		for i in range(LevelData.unused_planets.size()):
			LevelData.unused_planets[i].global_position = Vector2(40000, 40000)
			LevelData.unused_planets[i].name = "Unused Planet" + str(i)


func save_ship_data(enemy_array:Array[FactionCharacter] = LevelData.enemyShips, neutral_array:Array[NeutralCharacter] = LevelData.neutralShips) -> void:
	var current_system:Dictionary = LevelData.all_systems_data[Navigation.currentSystem]
	
	current_system.get("enemies")
	current_system.get("neutrals")
	
	#if current_system["enemies"].is_empty():
		#current_system["enemies_defeated"] = true
	for ship:FactionCharacter in enemy_array:
		current_system["enemies"][str(ship.name)] = {
			"position": ship.global_position,
			"shield_state":ship.shield_on,
			"movement_target": ship.moveTarget,
			"max_hp": ship.hp_max,
			"max_sp": ship.shield.sp_max,
			"current_hp": ship.hp_current,
			"current_sp": ship.shield.sp_current,
		}
	#if current_system["neuwdtrals"].is_empty():
		#current_system["neutrals_defeated"] = true
	for ship:NeutralCharacter in neutral_array:
		current_system["neutrals"][str(ship.name)] = {
			"position": ship.global_position,
			"shield_state":ship.shield_on,
			"movement_target": ship.moveTarget,
			"max_hp": ship.hp_max,
			"max_sp": ship.shield.sp_max,
			"current_hp": ship.hp_current,
			"current_sp": ship.shield.sp_current,
		}
	SignalBus.updateLevelData.emit(LevelData.all_systems_data)


func cleanup_old_system() -> void:
	var old_upgrade_drops:Array[Node] = get_tree().get_nodes_in_group("upgrade_drop")
	for drop:Area2D in old_upgrade_drops: # Delete all upgrade drops
		drop.queue_free()
	
	for ship:CharacterBody2D in LevelData.neutralShips + LevelData.enemyShips:
		ship.free() # Delete all old ships
	
	LevelData.enemyShips.clear()
	LevelData.neutralShips.clear()


func instantiate_new_system_nodes() -> void:
	var level_folder:Node = $level_objects
	
	var init_border: Node2D = levelBorders.instantiate()
	level_folder.add_child(init_border)
	init_border.add_to_group("level_nodes")

	var init_sun: Node2D = Sun.instantiate()
	level_folder.add_child(init_sun)
	init_sun.add_to_group("level_nodes")

	var init_starbase: Node2D = Starbase.instantiate()
	level_folder.add_child(init_starbase)
	init_starbase.global_position = Vector2.ZERO
	init_starbase.add_to_group("level_nodes")

	var init_spawn: Area2D = PlayerSpawnArea.instantiate()
	level_folder.add_child(init_spawn)
	init_spawn.add_to_group("level_nodes")
	init_spawn.add_to_group("player_spawn_area")

	for i in range(6): # Spawn 6 planets for use in level gen
		var init_planet: Node2D = Planet.instantiate()
		level_folder.add_child(init_planet)
		init_planet.global_position = Vector2(40000, 40000) # Moves planets outside of level borders

	var init_player: Player = Player.instantiate()
	add_child(init_player)
	LevelData.player = init_player
	init_player.add_to_group("level_nodes")
