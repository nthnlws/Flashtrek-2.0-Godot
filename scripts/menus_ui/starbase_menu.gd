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

@onready var stardate: Label = $Stardate
@onready var top_security: Label = $TopSecurity
@onready var bottom_security: Label = $BottomSecurity
@onready var faction_title: RichTextLabel = $FactionTitle
@onready var faction_border: TextureRect = $FactionBorder
@onready var ship_grid: GridContainer = %ShipGrid
@onready var ambience: AudioStreamPlayer = $ambience

var frames: Array[ShipSelector]
var _scaled_ship_stats: Dictionary[Utility.SHIP_TYPES, Dictionary]
var _stat_ranges: Dictionary = {}
const SHIP_SELECTOR = preload("uid://djjxdvhjd147f")

const BUTTON_COLORS: Dictionary = {
	Utility.FACTION.FEDERATION: {
		0: Color("ff9a66"), 1: Color("faa747"), 2: Color("fdc07e"),
		3: Color("f5b890"), 4: Color("e18f7b"), 5: Color("cd6667"),
	},
	Utility.FACTION.KLINGON: {
		0: Color("AE9656"), 1: Color("A47F49"), 2: Color("9B683C"),
		3: Color("915130"), 4: Color("883A23"), 5: Color("7E2316"),
	},
	Utility.FACTION.ROMULAN: {
		0: Color("438056"), 1: Color("3f886b"), 2: Color("3a9080"),
		3: Color("4e9f7d"), 4: Color("79b464"), 5: Color("a4ca4b"),
	},
}

var STARDATES: Dictionary[Utility.FACTION, String] = {
	Utility.FACTION.FEDERATION: "Stardate: %.2f" % Utility.get_federation_date(),
	Utility.FACTION.KLINGON:    Utility.get_klingon_date(),
	Utility.FACTION.ROMULAN:    Utility.get_romulan_date(),
}

var security_texts: Dictionary[Utility.FACTION, String] = {
	Utility.FACTION.FEDERATION: "Security Level 4",
	Utility.FACTION.ROMULAN:    "Security Clearance: Veridian 4",
	Utility.FACTION.KLINGON:    "Guard Access: Level 4",
	Utility.FACTION.NEUTRAL:    "Credit Rating: AA+",
}

var title_texts: Dictionary[Utility.FACTION, String] = {
	Utility.FACTION.FEDERATION: "Federation Starship Registry",
	Utility.FACTION.ROMULAN:    "Romulan Imperial Shipyard",
	Utility.FACTION.KLINGON:    "Klingon Imperial Shipyard",
	Utility.FACTION.NEUTRAL:    "[color=b27f65]Ferengi Trading Post",
}


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"): change_faction(Utility.FACTION.FEDERATION)
	if event.is_action_pressed("debug2"): change_faction(Utility.FACTION.ROMULAN)
	if event.is_action_pressed("debug3"): change_faction(Utility.FACTION.KLINGON)
	if event.is_action_pressed("debug4"): change_faction(Utility.FACTION.NEUTRAL)


func _ready() -> void:
	MissionManager.Reputation.reputation_total_changed.connect(_update_ship_unlocks)

	# Build all scaled stats up front across every faction roster
	_build_all_ship_stats()
	_cache_stat_ranges()

	if LevelManager.galaxy_data:
		SignalBus.player_type_changed.emit.call_deferred(
			LevelManager.galaxy_data.player_ship_type,
			_scaled_ship_stats.get(LevelManager.galaxy_data.player_ship_type))


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
		var stat_scale: float = Scaling.get_player_stat_scale(i, total)
		var move_scale: float = Scaling.get_player_move_scale(i, total)
		_add_ship_stats(ship_type, stat_scale, move_scale)


func _add_ship_stats(ship_type: Utility.SHIP_TYPES, stat_scale: float, move_scale: float) -> void:
	var base: Dictionary     = Utility.SHIP_DATA[ship_type]
	var faction: Utility.FACTION   = base.FACTION
	var archetype: Scaling.ARCHETYPE = base.ARCHETYPE

	_scaled_ship_stats[ship_type] = {
		"FACTION":			faction,
		"SHIP_NAME":		base.SHIP_NAME,
		"ARCHETYPE":		archetype,
		"TRAIT":			base.TRAIT,
		"MAX_HP":			Scaling.apply_modifiers(base.MAX_HP,                   stat_scale, archetype, faction, "MAX_HP"),
		"MAX_SHIELD":		Scaling.apply_modifiers(base.MAX_SHIELD,               stat_scale, archetype, faction, "MAX_SHIELD"),
		"SPEED":     		Scaling.apply_modifiers(base.PLAYER_SPEED_OVERRIDE,    move_scale, archetype, faction, "SPEED"),
		"ROTATION_SPEED":	Scaling.apply_modifiers(base.PLAYER_ROTATION_OVERRIDE, move_scale, archetype, faction, "ROTATION_SPEED"),
	}


func _cache_stat_ranges() -> void:
	_stat_ranges["MAX_HP"]    = Scaling.get_playable_stat_range("MAX_HP",    _scaled_ship_stats)
	_stat_ranges["MAX_SHIELD"]= Scaling.get_playable_stat_range("MAX_SHIELD",_scaled_ship_stats)
	_stat_ranges["SPEED"]     = Scaling.get_playable_stat_range("SPEED",     _scaled_ship_stats)
	_stat_ranges["ROTATION_SPEED"]  = Scaling.get_playable_stat_range("ROTATION_SPEED",  _scaled_ship_stats)


# ─── Faction Change ───────────────────────────────────────────────────────────

func change_faction(new_faction: Utility.FACTION) -> void:
	stardate.text      = STARDATES.get(new_faction, "Stardate: %.2f" % Utility.get_federation_date())
	faction_title.text = title_texts.get(new_faction, "")
	for label: Label in security_labels:
		label.text = security_texts.get(new_faction, "")
	var button_colors: Dictionary = BUTTON_COLORS.get(new_faction, {})
	for i: int in ship_buttons.size():
		ship_buttons[i].self_modulate = button_colors.get(i, Color.WHITE)
		if new_faction == Utility.FACTION.NEUTRAL:
			ship_buttons[i].texture = MENU_BUTTON_ROUNDED_COPPER
	faction_border.texture = faction_backgrounds.get(new_faction)
	update_selection_grid(new_faction)


# ─── Grid ─────────────────────────────────────────────────────────────────────

func update_selection_grid(faction: Utility.FACTION) -> void:
	for frame: Node in get_tree().get_nodes_in_group("ship_selection_frame"):
		frame.free()
	frames.clear()

	var unlock_ships: Array[Utility.SHIP_TYPES] = _get_faction_unlocks(faction)
	ship_grid.columns = ceili(sqrt(float(unlock_ships.size())))
	
	# Create ship frames
	for i: int in unlock_ships.size():
		var ship_type: Utility.SHIP_TYPES = unlock_ships[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, unlock_ships.size())
		var frame: ShipSelector = create_frame(ship_type, faction, unlock_cost)
		%ShipGrid.add_child(frame)
		frames.append(frame)
		# Update buttons to ship names
		if i < ship_buttons.size():
			ship_buttons[i].set_text(Utility.SHIP_TYPES.keys()[ship_type].replace("_", " "))
			ship_buttons[i].visible = true

	# Hide any buttons beyond the current faction's unlock dict size
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
	if ship_type == Utility.starting_ship:
		frame.unlock_price = 0
		frame.grayed_out   = false
	frame.icon_selected.connect(_on_ship_selected)
	frame.icon_hovered.connect(update_ship_stats)
	return frame


# ─── Ship Stats Display ───────────────────────────────────────────────────────

## Updates when selector is hovered
func update_ship_stats(selected_ship: ShipSelector) -> void:
	var faction: Utility.FACTION       = selected_ship.ship_faction
	var ship_type: Utility.SHIP_TYPES  = selected_ship.current_ship_type
	var ship_stats: Dictionary         = _scaled_ship_stats[ship_type]

	_set_stat_bar(%HealthBar,   ship_stats.MAX_HP,				_stat_ranges["MAX_HP"])
	_set_stat_bar(%ShieldBar,   ship_stats.MAX_SHIELD,			_stat_ranges["MAX_SHIELD"])
	_set_stat_bar(%SpeedBar,    ship_stats.SPEED,				_stat_ranges["SPEED"])
	_set_stat_bar(%MovementBar, ship_stats.ROTATION_SPEED,		_stat_ranges["ROTATION_SPEED"])
	
	var formatted_name:String = Utility.fed_blue + ship_stats.get("SHIP_NAME", "Missing").capitalize()
	%ship_name.text = "[color=#FFCC66]Ship Name:[/color] %s" % formatted_name

	var my_rep: float  = MissionManager.Reputation.get_reputation(faction)
	var req_rep: int   = selected_ship.unlock_price
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
			frame.set_gray_out(new_score <= frame.unlock_price)


func _on_ship_selected(ship_type: Utility.SHIP_TYPES) -> void:
	SignalBus.player_type_changed.emit(ship_type, _scaled_ship_stats.get(ship_type))
	LevelManager.galaxy_data.player_ship_type = ship_type
	close_menu()


func close_menu() -> void:
	visible = false
	menu_closed.emit()


func _on_visibility_changed() -> void:
	# Changing status to VISIBLE
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
	# Changing status to HIDDEN
	elif not visible:
		for frame: ShipSelector in frames:
			frame.queue_free()
		frames.clear()


func start_ambience() -> void:
	ambience.volume_db = -25
	ambience.play()
	var tween: Tween = create_tween()
	tween.tween_property(ambience, "volume_db", -20, 4.0)
