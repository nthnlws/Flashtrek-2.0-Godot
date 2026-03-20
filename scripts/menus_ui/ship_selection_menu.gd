extends Control
 
@onready var ambience: AudioStreamPlayer = $ambience
@onready var frames: Array[ShipSelector] = []

signal menu_closed

@export var federation_unlocks: Array[Utility.SHIP_TYPES]
@export var klingon_unlocks: Array[Utility.SHIP_TYPES]
@export var romulan_unlocks: Array[Utility.SHIP_TYPES]
@export var neutral_unlocks: Array[Utility.SHIP_TYPES]

const SHIP_SELECTOR: PackedScene = preload("uid://djjxdvhjd147f")

var _scaled_ship_stats: Dictionary[Utility.SHIP_TYPES, Dictionary] = {}

func _ready() -> void:
	MissionManager.Reputation.reputation_total_changed.connect(_update_ship_unlocks)
	
	update_selection_grid()
	update_all_faction_unlocks()
	
	# Update starting ship type after Upgrade Menu is ready
	SignalBus.player_type_changed.emit.call_deferred(LevelManager.galaxy_data.player_ship_type, _scaled_ship_stats.get(LevelManager.galaxy_data.player_ship_type))

func update_all_faction_unlocks() -> void:
	_update_ship_unlocks(Utility.FACTION.FEDERATION, MissionManager.Reputation.FederationRep)
	_update_ship_unlocks(Utility.FACTION.KLINGON, MissionManager.Reputation.KlingonRep)
	_update_ship_unlocks(Utility.FACTION.ROMULAN, MissionManager.Reputation.RomulanRep)
	_update_ship_unlocks(Utility.FACTION.NEUTRAL, MissionManager.Reputation.NeutralRep)


func update_selection_grid() -> void:
	# Clear old frames
	var old_frames: Array[Node] = get_tree().get_nodes_in_group("ship_selection_frame")
	for frame: Node in old_frames:
		frame.free()

	# Create new frames
	for i: int in range(federation_unlocks.size()):
		var ship_type: Utility.SHIP_TYPES = federation_unlocks[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, federation_unlocks.size())
		var stats_multiplier: float = Scaling.get_player_stat_scale(i, federation_unlocks.size())
		var move_multiplier: float = Scaling.get_player_move_scale(i, federation_unlocks.size())
		add_ship_stats(ship_type, Utility.FACTION.FEDERATION, stats_multiplier, move_multiplier)
		var frame: ShipSelector = create_frame(ship_type, Utility.FACTION.FEDERATION, unlock_cost)
		%FederationGrid.add_child(frame)
		frames.append(frame)
	for i: int in range(klingon_unlocks.size()):
		var ship_type: Utility.SHIP_TYPES = klingon_unlocks[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, klingon_unlocks.size())
		var stats_multiplier: float = Scaling.get_player_stat_scale(i, klingon_unlocks.size())
		var move_multiplier: float = Scaling.get_player_move_scale(i, klingon_unlocks.size())
		add_ship_stats(ship_type, Utility.FACTION.KLINGON, stats_multiplier, move_multiplier)
		var frame: ShipSelector = create_frame(ship_type, Utility.FACTION.KLINGON, unlock_cost)
		%KlingonGrid.add_child(frame)
		frames.append(frame)
	for i: int in range(romulan_unlocks.size()):
		var ship_type: Utility.SHIP_TYPES = romulan_unlocks[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, romulan_unlocks.size())
		var stats_multiplier: float = Scaling.get_player_stat_scale(i, romulan_unlocks.size())
		var move_multiplier: float = Scaling.get_player_move_scale(i, romulan_unlocks.size())
		add_ship_stats(ship_type, Utility.FACTION.ROMULAN, stats_multiplier, move_multiplier)
		var frame: ShipSelector = create_frame(ship_type, Utility.FACTION.ROMULAN, unlock_cost)
		%RomulanGrid.add_child(frame)
		frames.append(frame)
	for i: int in range(neutral_unlocks.size()):
		var ship_type: Utility.SHIP_TYPES = neutral_unlocks[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, neutral_unlocks.size())
		var stats_multiplier: float = Scaling.get_player_stat_scale(i, neutral_unlocks.size())
		var move_multiplier: float = Scaling.get_player_move_scale(i, neutral_unlocks.size())
		add_ship_stats(ship_type, Utility.FACTION.NEUTRAL, stats_multiplier, move_multiplier)
		var frame: ShipSelector = create_frame(ship_type, Utility.FACTION.NEUTRAL, unlock_cost)
		%NeutralGrid.add_child(frame)
		frames.append(frame)


func update_ship_stats(selected_ship: ShipSelector) -> void:
	var faction: Utility.FACTION = selected_ship.ship_faction
	var ship_stats: Dictionary = _scaled_ship_stats[selected_ship.current_ship_type]

	%ship_name.text = "Ship Name: " + Utility.UI_ship_lime + ship_stats.SHIP_NAME.replace("_", " ")
	%health_stat.text = "Health: %s" % ship_stats.MAX_HP
	%shield_stat.text = "Shield: %s" % ship_stats.MAX_SHIELD
	%weapon.text = "Default Weapon: Torpedo"
	%speed_stat.text = "Max Speed: %s" % ship_stats.SPEED
	%maneuver_stat.text = "Maneuverability: %s" % ship_stats.ROTATION_SPEED

	var faction_color: String
	match faction:
		Utility.FACTION.FEDERATION: faction_color = Utility.fed_blue
		Utility.FACTION.KLINGON:    faction_color = Utility.klin_red
		Utility.FACTION.ROMULAN:    faction_color = Utility.rom_green
		Utility.FACTION.NEUTRAL:    faction_color = Utility.neut_cyan
		_:                          faction_color = Utility.UI_ship_lime
	%faction.text = "Faction: " + faction_color + str(Utility.FACTION.keys()[faction]).to_pascal_case()

	var my_rep: float = MissionManager.Reputation.get_reputation(faction)
	var req_rep: int = selected_ship.unlock_price

	if req_rep == 0:
		%price_banner.text = "Unlocked: %sDefault" % Utility.UI_cargo_green
	elif my_rep >= req_rep:
		%price_banner.text = "Reputation Required: %s%s" % [Utility.UI_cargo_green, req_rep]
	else:
		%price_banner.text = "Reputation Required: %s%s" % [Utility.damage_red, req_rep]


func add_ship_stats(ship_type: Utility.SHIP_TYPES, ship_faction:Utility.FACTION, stats_multiplier: float, move_multiplier: float) -> void:
	var base: Dictionary = Utility.SHIP_STATS[ship_type]
	_scaled_ship_stats[ship_type] = {
		"SHIP_NAME": 			Utility.SHIP_TYPES.keys()[ship_type],
		"MAX_HP": 				snapped(base.MAX_HP * stats_multiplier, 10),
		"MAX_SHIELD": 			snapped(base.MAX_SHIELD * stats_multiplier, 10),
		"SPEED": 				snapped(base.PLAYER_SPEED_OVERRIDE * move_multiplier, 10),
		"ROTATION_SPEED":		snapped(base.PLAYER_ROTATION_OVERRIDE * move_multiplier, 10),
		"DAMAGE_MULTIPLIER":	snapped(stats_multiplier, 0.1),
		"FACTION":				ship_faction,
	}


func create_frame(ship_type: Utility.SHIP_TYPES, faction: Utility.FACTION, unlock_cost: int) -> ShipSelector:
	var frame: ShipSelector = SHIP_SELECTOR.instantiate()
	frame.current_ship_type = ship_type
	frame.ship_faction = faction
	frame.unlock_price = unlock_cost
	if ship_type == Utility.starting_ship:
		frame.unlock_price = 0
		frame.grayed_out = false
	frame.icon_selected.connect(_on_ship_selected)
	frame.icon_hovered.connect(update_ship_stats)
	return frame


func _update_ship_unlocks(faction: Utility.FACTION, new_score: float) -> void:
	#print('updating ship unlocks for %s' % Utility.FACTION.keys()[faction])
	for frame: ShipSelector in frames:
		if frame.ship_faction == faction:
			if frame.unlock_price != 0: # If not default ship
				frame.set_gray_out(new_score <= frame.unlock_price)


func clear_stats() -> void:
		%ship_name.text = "Ship Name: "
		%faction.text = "Faction: "
		%health_stat.text = "Health: "
		%shield_stat.text = "Shield: "
		%weapon.text = "Default Weapon: "
		%speed_stat.text = "Max Speed: "
		%maneuver_stat.text = "Maneuverability: "
		%price_banner.text = "Reputation Required: "

func start_ambience() -> void:
	ambience.volume_db = -25
	ambience.play()
	var tween: Tween = create_tween()
	tween.tween_property(ambience, "volume_db", -20, 4.0)


func _on_ship_selected(ship_type: Utility.SHIP_TYPES) -> void:
	SignalBus.player_type_changed.emit(ship_type, _scaled_ship_stats.get(ship_type))
	LevelManager.galaxy_data.player_ship_type = ship_type
	close_menu()


func close_menu() -> void:
	self.visible = false
	menu_closed.emit()
