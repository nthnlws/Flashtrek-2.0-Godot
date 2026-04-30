extends Control
class_name StarbaseMenu

signal menu_closed

@export_category("Playable Ships")
@export var federation_unlocks: Array[Utility.SHIP_TYPES]
@export var klingon_unlocks: Array[Utility.SHIP_TYPES]
@export var romulan_unlocks: Array[Utility.SHIP_TYPES]
@export var neutral_unlocks: Array[Utility.SHIP_TYPES]

@export_category("Scene Nodes")
@export var security_labels: Array[Label]

@onready var stardate: Label = $Stardate
@onready var top_security: Label = $TopSecurity
@onready var bottom_security: Label = $BottomSecurity
@onready var faction_title: RichTextLabel = $FactionTitle
@onready var faction_border: TextureRect = $FactionBorder
@onready var ship_grid: GridContainer = %ShipGrid
@onready var ambience: AudioStreamPlayer = $ambience

var selection_buttons: Array[ShipCardButton]
var scaled_ship_stats: Dictionary[Utility.SHIP_TYPES, PlayableShipStats]
var _faction_stat_ranges: Dictionary[Utility.FACTION, Dictionary]
var _stat_ranges: Dictionary
const SHIP_CARD_BUTTON = preload("uid://qu0xx1uo0wsd")
const SELECTION_MENU_TEMPLATE = preload("uid://bd2odrgq4wa8e")
const SELECTION_MENU_NEUTRAL = preload("uid://db4asel4ucnxb")



const FACTION_DATA: Dictionary = {
	Utility.FACTION.FEDERATION: {
		"security":        "Security Level 4",
		"title":           "Federation Starship Registry",
		"button_colors":   [Color("FF9A66"), Color("F59066"), Color("EB8566"),
							Color("E17B67"), Color("D77067"), Color("CD6667")],
		"menu_color":		preload("uid://gc0h18tj2rpq"),
	},
	Utility.FACTION.KLINGON: {
		"security":        "Guard Access: Level 4",
		"title":           "Klingon Imperial Shipyard",
		"button_colors":   [Color("AE9656"), Color("A47F49"), Color("9B683C"),
							Color("915130"), Color("883A23"), Color("7E2316")],
		"menu_color":		preload("uid://dwulk1peb7b3f"),
	},
	Utility.FACTION.ROMULAN: {
		"security":        "Security Clearance: Veridian 4",
		"title":           "Romulan Imperial Shipyard",
		"button_colors":   [Color("A4CA4B"), Color("91BB4D"), Color("7DAC4F"),
							Color("6A9E52"), Color("568F54"), Color("438056")],
		"menu_color":		preload("uid://4di586ydcxup"),
	},
	Utility.FACTION.NEUTRAL: {
		"security":        "Credit Rating: AA+",
		"title":           "[color=b27f65]Ferengi Trading Post",
		"button_colors":   [Color(1.0, 1.0, 1.0)],
		"menu_color":		preload("uid://d3rdh06w7l4xe"),
	},
}


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"): change_faction(Utility.FACTION.FEDERATION)
	if event.is_action_pressed("debug2"): change_faction(Utility.FACTION.ROMULAN)
	if event.is_action_pressed("debug3"): change_faction(Utility.FACTION.KLINGON)
	if event.is_action_pressed("debug4"): change_faction(Utility.FACTION.NEUTRAL)


func _ready() -> void:
	MissionManager.Reputation.reputation_total_changed.connect(_update_ship_unlocks)
	_cache_faction_ranges()
	_build_all_ship_stats()
	_cache_stat_ranges()
	if LevelManager.galaxy_data:
		SignalBus.player_type_changed.emit.call_deferred(
			LevelManager.galaxy_data.player_ship_type,
			scaled_ship_stats.get(LevelManager.galaxy_data.player_ship_type))


# ─── Stats Pre-Build ──────────────────────────────────────────────────────────

func _build_all_ship_stats() -> void:
	_build_faction_stats(federation_unlocks)
	_build_faction_stats(klingon_unlocks)
	_build_faction_stats(romulan_unlocks)
	_build_faction_stats(neutral_unlocks)


func _build_faction_stats(unlock_list: Array[Utility.SHIP_TYPES]) -> void:
	var total: float = float(unlock_list.size())
	for index: int in total:
		var ship_type: Utility.SHIP_TYPES = unlock_list[index]
		_add_ship_stats(ship_type,
			Scaling.get_player_stat_scale(index / total),
			Scaling.get_player_move_scale(index / total),
			Scaling.get_player_energy_scale(index / total),
			index,
			_faction_stat_ranges)


func _cache_faction_ranges() -> void:
	_faction_stat_ranges[Utility.FACTION.FEDERATION] = Scaling.get_faction_stat_range(federation_unlocks, Utility.FACTION.FEDERATION)
	_faction_stat_ranges[Utility.FACTION.KLINGON]    = Scaling.get_faction_stat_range(klingon_unlocks,    Utility.FACTION.KLINGON)
	_faction_stat_ranges[Utility.FACTION.ROMULAN]    = Scaling.get_faction_stat_range(romulan_unlocks,    Utility.FACTION.ROMULAN)
	_faction_stat_ranges[Utility.FACTION.NEUTRAL]    = Scaling.get_faction_stat_range(neutral_unlocks,    Utility.FACTION.NEUTRAL)


func _add_ship_stats(ship_type: Utility.SHIP_TYPES, stat_scale: float, move_scale: float, energy_scale: float, index:int, stat_ranges:Dictionary[Utility.FACTION, Dictionary]) -> void:
	var base: Dictionary         = Utility.SHIP_DATA[ship_type]
	var faction: Utility.FACTION = base.FACTION
	var archetype: Scaling.ARCHETYPE = base.ARCHETYPE
	
	var stats: PlayableShipStats = PlayableShipStats.new()
	stats.faction        = faction
	stats.ship_name      = base.SHIP_NAME
	stats.archetype      = archetype
	stats.trait_type     = base.TRAIT
	stats.damage_mult    = Scaling.apply_modifiers(1.0,                           stat_scale, archetype, faction, "DAMAGE")
	stats.max_hp         = Scaling.apply_modifiers(base.MAX_HP,                   stat_scale, archetype, faction, "MAX_HP")
	stats.max_shield     = Scaling.apply_modifiers(base.MAX_SHIELD,               stat_scale, archetype, faction, "MAX_SHIELD")
	stats.speed          = Scaling.apply_modifiers(base.PLAYER_SPEED_OVERRIDE,    move_scale, archetype, faction, "SPEED")
	stats.agility        = Scaling.apply_modifiers(base.PLAYER_AGILITY_OVERRIDE, move_scale, archetype, faction, "AGILITY")
	stats.warp_range     = Scaling.get_ship_warp_range(index)
	stats.stat_ranges    = stat_ranges
	stats.max_energy     = snappedi(150 * energy_scale, 25)
	
	scaled_ship_stats[ship_type] = stats


func _cache_stat_ranges() -> void:
	_stat_ranges["MAX_HP"]         = Scaling.get_playable_stat_range("max_hp",         scaled_ship_stats)
	_stat_ranges["MAX_SHIELD"]     = Scaling.get_playable_stat_range("max_shield",      scaled_ship_stats)
	_stat_ranges["SPEED"]          = Scaling.get_playable_stat_range("speed",           scaled_ship_stats)
	_stat_ranges["AGILITY"]        = Scaling.get_playable_stat_range("agility",  scaled_ship_stats)


# ─── Faction Change ───────────────────────────────────────────────────────────
func change_faction(new_faction: Utility.FACTION) -> void:
	var faction_data: Dictionary = FACTION_DATA.get(new_faction, {})

	stardate.text      = _get_stardate(new_faction)
	faction_title.text = faction_data.get("title", "")

	for label: Label in security_labels:
		label.text = faction_data.get("security", "")

	var button_colors: Array = faction_data.get("button_colors", [])
	for i: int in selection_buttons.size():
		if new_faction != Utility.FACTION.NEUTRAL:
			selection_buttons[i].set_copper_state(false)
			selection_buttons[i].self_modulate = button_colors[i] if i < button_colors.size() else Color.WHITE
		else: # Neutral buttons
			selection_buttons[i].set_copper_state(true)
	
	# Update menu frame colors
	faction_border.material = faction_data.get("menu_color") # Set faction shader
	if new_faction != Utility.FACTION.NEUTRAL:
		faction_border.texture = SELECTION_MENU_TEMPLATE
	else: # Neutral faction frame
		faction_border.texture = SELECTION_MENU_NEUTRAL
	update_selection_grid(new_faction)


func _get_stardate(faction: Utility.FACTION) -> String:
	match faction:
		Utility.FACTION.FEDERATION: return "Stardate: %.2f" % Utility.get_federation_date()
		Utility.FACTION.KLINGON:    return Utility.get_klingon_date()
		Utility.FACTION.ROMULAN:    return Utility.get_romulan_date()
		_:                          return "Stardate: %.2f" % Utility.get_federation_date()


# ─── Grid ─────
func update_selection_grid(faction: Utility.FACTION) -> void:
	for button: ShipCardButton in get_tree().get_nodes_in_group("ship_card_button"):
		button.queue_free()
	selection_buttons.clear()

	var unlock_ships: Array[Utility.SHIP_TYPES] = _get_faction_unlocks(faction)
	ship_grid.columns = mini(2, unlock_ships.size())

	for i: int in unlock_ships.size():
		var ship_type: Utility.SHIP_TYPES = unlock_ships[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i / float(unlock_ships.size()))
		var button: ShipCardButton = create_ship_button(ship_type, faction, unlock_cost)
		button.add_to_group("ship_card_button")
		%ShipGrid.add_child(button)
		selection_buttons.append(button)
		if faction != Utility.FACTION.NEUTRAL:
			button.set_copper_state(false)
			button.update_color(FACTION_DATA.get(faction, {}).get("button_colors", [])[i])
		else:
			button.set_copper_state(true)


func _get_faction_unlocks(faction: Utility.FACTION) -> Array[Utility.SHIP_TYPES]:
	match faction:
		Utility.FACTION.FEDERATION: return federation_unlocks
		Utility.FACTION.KLINGON:    return klingon_unlocks
		Utility.FACTION.ROMULAN:    return romulan_unlocks
		Utility.FACTION.NEUTRAL:    return neutral_unlocks
		_:                          return []


func create_ship_button(ship_type: Utility.SHIP_TYPES, faction: Utility.FACTION, unlock_cost: int) -> ShipCardButton:
	var button: ShipCardButton = SHIP_CARD_BUTTON.instantiate()
	button.current_ship_type = ship_type
	button.ship_faction      = faction
	button.unlock_price      = unlock_cost
	if ship_type == Utility.starting_ship:
		button.unlock_price = 0
		button.grayed_out   = false
	button.released.connect(_on_ship_selected)
	button.hovered.connect(update_ship_stats)
	return button


# ─── Ship Stats Display ───────────────────────────────────────────────────────
func update_ship_stats(selected_ship: ShipCardButton) -> void:
	var faction: Utility.FACTION      = selected_ship.ship_faction
	var ship_type: Utility.SHIP_TYPES = selected_ship.current_ship_type
	var stats: PlayableShipStats      = scaled_ship_stats[ship_type]

	# Existing stat bars unchanged
	_set_stat_bar(%HealthBar,   stats.max_hp,         _stat_ranges["MAX_HP"])
	_set_stat_bar(%ShieldBar,   stats.max_shield,     _stat_ranges["MAX_SHIELD"])
	_set_stat_bar(%SpeedBar,    stats.speed,          _stat_ranges["SPEED"])
	_set_stat_bar(%MovementBar, stats.agility,        _stat_ranges["AGILITY"])

	var formatted_name: String = Utility.fed_blue + stats.ship_name.capitalize()
	%ship_name.text = "[color=#FFCC66]Ship Name:[/color] %s" % formatted_name


func _safe_div(value: float, max_val: float) -> float:
	if max_val <= 0.0:
		return 0.0
	return clampf(value / max_val, 0.0, 1.0)


func _set_stat_bar(bar: Control, value: float, range: Vector2, min_fill: float = 0.2, contrast: float = 0.6) -> void:
	if range.y <= range.x:
		bar.set_progress(min_fill * 100.0)
		return
	var t: float       = clampf((value - range.x) / (range.y - range.x), 0.0, 1.0)
	var curved: float  = pow(t, contrast)
	var display: float = lerpf(min_fill, 1.0, curved)
	bar.set_progress(display * 100.0)


# ─── Unlock Updates ───────────────────────────────────────────────────────────

func _update_ship_unlocks(faction: Utility.FACTION, new_score: float) -> void:
	for button: ShipCardButton in selection_buttons:
		if button.ship_faction == faction and button.unlock_price != 0:
			button.set_unlock_cost(button.unlock_price, new_score >= button.unlock_price)
			button.set_gray_out(new_score < button.unlock_price)


func _on_ship_selected(ship_type: Utility.SHIP_TYPES) -> void:
	SignalBus.player_type_changed.emit(ship_type, scaled_ship_stats.get(ship_type))
	LevelManager.galaxy_data.player_ship_type = ship_type
	close_menu()


func close_menu() -> void:
	visible = false
	menu_closed.emit()


func _on_visibility_changed() -> void:
	if LevelManager.galaxy_data and visible:
		var faction: Utility.FACTION = LevelManager.galaxy_data.current_system.faction
		var rep_mapping: Dictionary[Utility.FACTION, float] = {
			Utility.FACTION.FEDERATION: MissionManager.Reputation.FederationRep,
			Utility.FACTION.KLINGON:    MissionManager.Reputation.KlingonRep,
			Utility.FACTION.ROMULAN:    MissionManager.Reputation.RomulanRep,
			Utility.FACTION.NEUTRAL:    MissionManager.Reputation.NeutralRep,
		}
		change_faction(faction)
		_update_ship_unlocks(faction, rep_mapping[faction])
	elif not visible:
		for button: ShipCardButton in selection_buttons:
			button.queue_free()
		selection_buttons.clear()
		stop_ambience()


func start_ambience() -> void:
	ambience.play()
	var tween: Tween = create_tween()
	tween.tween_property(ambience, "volume_db", -20, 4.0)

func stop_ambience() -> void:
	if ambience: ambience.stop()
