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
var scaled_ship_stats: Dictionary[Utility.SHIP_TYPES, BaseShipInfo]
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
	clear_buttons()
	MissionManager.Reputation.reputation_total_changed.connect(_update_ship_unlocks)


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
func clear_buttons() -> void:
	for button: ShipCardButton in get_tree().get_nodes_in_group("ship_card_button"):
		button.queue_free()
	selection_buttons.clear()


func update_selection_grid(faction: Utility.FACTION) -> void:
	clear_buttons()

	var unlock_ships: Array[Utility.SHIP_TYPES] = _get_faction_unlocks(faction)
	var array_size: int = unlock_ships.size()
	ship_grid.columns = mini(2, array_size)

	for i: int in range(array_size):
		var ship_info: BaseShipInfo = Utility.get_ship_stats(unlock_ships[i])
		var scaled_info: ShipState = ShipState.get_player_scaled_stats(i, array_size, ship_info)
		var button: ShipCardButton = ShipCardButton.create_ship_button(scaled_info)
		# Connect new button signals
		button.released.connect(_on_ship_selected)
		button.hovered.connect(update_ship_stats)
		
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


# ─── Ship Stats Display ───────────────────────────────────────────────────────
func update_ship_stats(selected_ship: ShipCardButton) -> void:
	var ship_info: ShipState = selected_ship.ship_info

	# Existing stat bars unchanged
	_set_stat_bar(%HealthBar,   ship_info.scaled_max_HP,         _stat_ranges["MAX_HP"])
	_set_stat_bar(%ShieldBar,   ship_info.scaled_max_shield,     _stat_ranges["MAX_SHIELD"])
	_set_stat_bar(%SpeedBar,    ship_info.scaled_speed,          _stat_ranges["SPEED"])
	_set_stat_bar(%MovementBar, ship_info.scaled_agility,        _stat_ranges["AGILITY"])

	var formatted_name: String = Utility.fed_blue + ship_info.ship_name.capitalize()
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
		var cost: float = button.ship_info.unlock_cost
		if button.ship_info.current_faction == faction and cost != 0:
			button.set_unlock_cost(cost, new_score >= cost)
			button.set_gray_out(new_score < cost)


func _on_ship_selected(clicked_button:ShipCardButton) -> void:
	SignalBus.player_type_changed.emit(clicked_button.ship_info)
	close_menu()


func close_menu() -> void:
	visible = false
	menu_closed.emit()


func _on_visibility_changed() -> void:
	if visible:
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
