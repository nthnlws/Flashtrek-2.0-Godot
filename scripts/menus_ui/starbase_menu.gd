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
@export var ship_buttons: Array[RoundedButton]
@export var title_label: Label

@export_category("Assets")
@export var faction_backgrounds: Dictionary[Utility.FACTION, Texture]
const MENU_BUTTON_ROUNDED_COPPER = preload("uid://cuuk6xjyayqmn")
const MENU_BUTTON_ROUNDED = preload("uid://cpd0paggi412v")

@onready var stardate: Label = $Stardate
@onready var top_security: Label = $TopSecurity
@onready var bottom_security: Label = $BottomSecurity
@onready var faction_title: RichTextLabel = $FactionTitle
@onready var faction_border: TextureRect = $FactionBorder
@onready var ship_grid: GridContainer = %ShipGrid
@onready var ambience: AudioStreamPlayer = $ambience

var frames: Array[ShipSelector]
var scaled_ship_stats: Dictionary[Utility.SHIP_TYPES, PlayableShipStats]
var _stat_ranges: Dictionary = {}
const SHIP_SELECTOR = preload("uid://djjxdvhjd147f")

const FACTION_DATA: Dictionary = {
	Utility.FACTION.FEDERATION: {
		"security":        "Security Level 4",
		"title":           "Federation Starship Registry",
		"button_colors":   [Color("ff9a66"), Color("faa747"), Color("fdc07e"),
							Color("f5b890"), Color("e18f7b"), Color("cd6667")],
		"copper_buttons":  false,
	},
	Utility.FACTION.KLINGON: {
		"security":        "Guard Access: Level 4",
		"title":           "Klingon Imperial Shipyard",
		"button_colors":   [Color("AE9656"), Color("A47F49"), Color("9B683C"),
							Color("915130"), Color("883A23"), Color("7E2316")],
		"copper_buttons":  false,
	},
	Utility.FACTION.ROMULAN: {
		"security":        "Security Clearance: Veridian 4",
		"title":           "Romulan Imperial Shipyard",
		"button_colors":   [Color("438056"), Color("3f886b"), Color("3a9080"),
							Color("4e9f7d"), Color("79b464"), Color("a4ca4b")],
		"copper_buttons":  false,
	},
	Utility.FACTION.NEUTRAL: {
		"security":        "Credit Rating: AA+",
		"title":           "[color=b27f65]Ferengi Trading Post",
		"button_colors":   [Color(1.0, 1.0, 1.0)],
		"copper_buttons":  true,
	},
}


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"): change_faction(Utility.FACTION.FEDERATION)
	if event.is_action_pressed("debug2"): change_faction(Utility.FACTION.ROMULAN)
	if event.is_action_pressed("debug3"): change_faction(Utility.FACTION.KLINGON)
	if event.is_action_pressed("debug4"): change_faction(Utility.FACTION.NEUTRAL)


func _ready() -> void:
	MissionManager.Reputation.reputation_total_changed.connect(_update_ship_unlocks)
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
	var total: int = unlock_list.size()
	for i: int in total:
		var ship_type: Utility.SHIP_TYPES = unlock_list[i]
		_add_ship_stats(ship_type,
			Scaling.get_player_stat_scale(i, total),
			Scaling.get_player_move_scale(i, total),
			Scaling.get_player_energy_scale(i, total), i)


func _add_ship_stats(ship_type: Utility.SHIP_TYPES, stat_scale: float, move_scale: float, energy_scale: float, index:int) -> void:
	var base: Dictionary         = Utility.SHIP_DATA[ship_type]
	var faction: Utility.FACTION = base.FACTION
	var archetype: Scaling.ARCHETYPE = base.ARCHETYPE
	var warp_ranges: Dictionary[int, int] = {
		0: 2,
		1: 2,
		2: 3,
		3: 4,
		4: 5,
		5: 6,
	}
	
	var stats: PlayableShipStats = PlayableShipStats.new()
	stats.faction        = faction
	stats.ship_name      = base.SHIP_NAME
	stats.archetype      = archetype
	stats.trait_type     = base.TRAIT
	stats.damage_mult    = energy_scale
	stats.max_hp         = Scaling.apply_modifiers(base.MAX_HP,                   stat_scale, archetype, faction, "MAX_HP")
	stats.max_shield     = Scaling.apply_modifiers(base.MAX_SHIELD,               stat_scale, archetype, faction, "MAX_SHIELD")
	stats.speed          = Scaling.apply_modifiers(base.PLAYER_SPEED_OVERRIDE,    move_scale, archetype, faction, "SPEED")
	stats.agility        = Scaling.apply_modifiers(base.PLAYER_AGILITY_OVERRIDE, move_scale, archetype, faction, "AGILITY")
	stats.warp_range     = warp_ranges.get(index, 2)
	
	scaled_ship_stats[ship_type] = stats


func _cache_stat_ranges() -> void:
	_stat_ranges["MAX_HP"]         = Scaling.get_playable_stat_range("max_hp",         scaled_ship_stats)
	_stat_ranges["MAX_SHIELD"]     = Scaling.get_playable_stat_range("max_shield",      scaled_ship_stats)
	_stat_ranges["SPEED"]          = Scaling.get_playable_stat_range("speed",           scaled_ship_stats)
	_stat_ranges["AGILITY"] = Scaling.get_playable_stat_range("agility",  scaled_ship_stats)


# ─── Faction Change ───────────────────────────────────────────────────────────

func change_faction(new_faction: Utility.FACTION) -> void:
	var faction_data: Dictionary = FACTION_DATA.get(new_faction, {})

	stardate.text      = _get_stardate(new_faction)
	faction_title.text = faction_data.get("title", "")

	for label: Label in security_labels:
		label.text = faction_data.get("security", "")

	var button_colors: Array = faction_data.get("button_colors", [])
	var use_copper: bool     = faction_data.get("copper_buttons", false)
	for i: int in ship_buttons.size():
		ship_buttons[i].self_modulate = button_colors[i] if i < button_colors.size() else Color.WHITE
		if use_copper: 		ship_buttons[i].texture = MENU_BUTTON_ROUNDED_COPPER
		else: 				ship_buttons[i].texture = MENU_BUTTON_ROUNDED

	faction_border.texture = faction_backgrounds.get(new_faction)
	update_selection_grid(new_faction)


func _get_stardate(faction: Utility.FACTION) -> String:
	match faction:
		Utility.FACTION.FEDERATION: return "Stardate: %.2f" % Utility.get_federation_date()
		Utility.FACTION.KLINGON:    return Utility.get_klingon_date()
		Utility.FACTION.ROMULAN:    return Utility.get_romulan_date()
		_:                          return "Stardate: %.2f" % Utility.get_federation_date()


# ─── Grid ─────────────────────────────────────────────────────────────────────

func update_selection_grid(faction: Utility.FACTION) -> void:
	for frame: Node in get_tree().get_nodes_in_group("ship_selection_frame"):
		frame.free()
	frames.clear()

	var unlock_ships: Array[Utility.SHIP_TYPES] = _get_faction_unlocks(faction)
	ship_grid.columns = ceili(sqrt(float(unlock_ships.size())))

	for i: int in unlock_ships.size():
		var ship_type: Utility.SHIP_TYPES = unlock_ships[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, unlock_ships.size())
		var frame: ShipSelector = create_frame(ship_type, faction, unlock_cost)
		%ShipGrid.add_child(frame)
		frames.append(frame)
		if i < ship_buttons.size():
			ship_buttons[i].set_text(Utility.SHIP_TYPES.keys()[ship_type].replace("_", " "))
			ship_buttons[i].visible = true

	for i: int in range(unlock_ships.size(), ship_buttons.size()):
		ship_buttons[i].visible = false


func _get_faction_unlocks(faction: Utility.FACTION) -> Array[Utility.SHIP_TYPES]:
	match faction:
		Utility.FACTION.FEDERATION: return federation_unlocks
		Utility.FACTION.KLINGON:    return klingon_unlocks
		Utility.FACTION.ROMULAN:    return romulan_unlocks
		Utility.FACTION.NEUTRAL:    return neutral_unlocks
		_:                          return []


func create_frame(ship_type: Utility.SHIP_TYPES, faction: Utility.FACTION, unlock_cost: int) -> ShipSelector:
	var frame: ShipSelector = SHIP_SELECTOR.instantiate()
	frame.current_ship_type = ship_type
	frame.ship_faction      = faction
	frame.unlock_price      = unlock_cost
	frame.ship_faction      = faction
	if ship_type == Utility.starting_ship:
		frame.unlock_price = 0
		frame.grayed_out   = false
	frame.icon_selected.connect(_on_ship_selected)
	frame.icon_hovered.connect(update_ship_stats)
	return frame


# ─── Ship Stats Display ───────────────────────────────────────────────────────

func update_ship_stats(selected_ship: ShipSelector) -> void:
	var faction: Utility.FACTION      = selected_ship.ship_faction
	var ship_type: Utility.SHIP_TYPES = selected_ship.current_ship_type
	var stats: PlayableShipStats              = scaled_ship_stats[ship_type]

	_set_stat_bar(%HealthBar,   stats.max_hp,         _stat_ranges["MAX_HP"])
	_set_stat_bar(%ShieldBar,   stats.max_shield,     _stat_ranges["MAX_SHIELD"])
	_set_stat_bar(%SpeedBar,    stats.speed,          _stat_ranges["SPEED"])
	_set_stat_bar(%MovementBar, stats.agility, _stat_ranges["AGILITY"])

	var formatted_name: String = Utility.fed_blue + stats.ship_name.capitalize()
	%ship_name.text = "[color=#FFCC66]Ship Name:[/color] %s" % formatted_name

	var my_rep: float = MissionManager.Reputation.get_reputation(faction)
	var req_rep: int  = selected_ship.unlock_price
	if req_rep == 0:
		%price_banner.text = "Unlocked: %sDefault" % Utility.UI_cargo_green
	elif my_rep >= req_rep:
		%price_banner.text = "Required Rep: %s%s" % [Utility.UI_cargo_green, req_rep]
	else:
		%price_banner.text = "Required Rep: %s%s" % [Utility.damage_red, req_rep]


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
	for frame: ShipSelector in frames:
		if frame.ship_faction == faction and frame.unlock_price != 0:
			frame.set_gray_out(new_score < frame.unlock_price)


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
		for frame: ShipSelector in frames:
			frame.queue_free()
		frames.clear()
		stop_ambience()


func start_ambience() -> void:
	ambience.play()
	var tween: Tween = create_tween()
	tween.tween_property(ambience, "volume_db", -20, 4.0)

func stop_ambience() -> void:
	if ambience: ambience.stop()
