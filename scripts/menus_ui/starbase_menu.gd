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

func _enter_tree() -> void:
	generate_all_faction_ranges()
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
		button.hovered.connect(%StatsContainer.update_ship_stats)
		
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

func generate_all_faction_ranges() -> void:
	Utility.factionStatRanges.clear()
	Utility.factionStatRanges.append(_create_faction_range(Utility.FACTION.FEDERATION, federation_unlocks))
	Utility.factionStatRanges.append(_create_faction_range(Utility.FACTION.KLINGON, klingon_unlocks))
	Utility.factionStatRanges.append(_create_faction_range(Utility.FACTION.ROMULAN, romulan_unlocks))
	Utility.factionStatRanges.append(_create_faction_range(Utility.FACTION.NEUTRAL, neutral_unlocks))

func _create_faction_range(faction: Utility.FACTION, unlock_list: Array[Utility.SHIP_TYPES]) -> FactionRanges:
	var res: FactionRanges = FactionRanges.new()
	res.faction = faction
	
	# Initialize minimums to infinity to allow correct minf() calculation
	res.max_hp_MIN = INF
	res.max_shield_MIN = INF
	res.speed_MIN = INF
	res.agility_MIN = INF
	res.damage_MIN = INF
	res.range_MIN = INF
	res.max_energy_MIN = INF
	
	var total: int = unlock_list.size()
	for i: int in total:
		var t: float = Scaling.get_norm_t(i, total)
		var ship_type: Utility.SHIP_TYPES = unlock_list[i]
		var base: BaseShipInfo = Utility.get_ship_stats(ship_type)
		var archetype: Scaling.ARCHETYPE = base.archetype
		
		var stat_mult: float = Scaling.get_player_stat_scale(t)
		var move_mult: float = Scaling.get_player_move_scale(t)
		var energy_scale: float = Scaling.get_player_energy_scale(t)
		
		# Calculate raw scaled values
		var c_hp:float = Scaling.apply_modifiers(base.base_HP, stat_mult, archetype, faction, "MAX_HP")
		var c_shield:float = Scaling.apply_modifiers(base.base_shield, stat_mult, archetype, faction, "MAX_SHIELD")
		var c_speed:float = Scaling.apply_modifiers(base.base_speed, move_mult, archetype, faction, "SPEED")
		var c_agility:float = Scaling.apply_modifiers(base.base_agility, move_mult, archetype, faction, "AGILITY")
		var c_damage:float = Scaling.apply_modifiers(1.0, stat_mult, archetype, faction, "DAMAGE")
		var c_range:float = float(Scaling.get_ship_warp_range(i))
		var c_energy:float = float(snappedi(150.0 * energy_scale, 25))
		
		# Track minimums and maximums
		res.max_hp_MIN = minf(res.max_hp_MIN, c_hp)
		res.max_hp_MAX = maxf(res.max_hp_MAX, c_hp)
		
		res.max_shield_MIN = minf(res.max_shield_MIN, c_shield)
		res.max_shield_MAX = maxf(res.max_shield_MAX, c_shield)
		
		res.speed_MIN = minf(res.speed_MIN, c_speed)
		res.speed_MAX = maxf(res.speed_MAX, c_speed)
		
		res.agility_MIN = minf(res.agility_MIN, c_agility)
		res.agility_MAX = maxf(res.agility_MAX, c_agility)
		
		res.damage_MIN = minf(res.damage_MIN, c_damage)
		res.damage_MAX = maxf(res.damage_MAX, c_damage)
		
		res.range_MIN = minf(res.range_MIN, c_range)
		res.range_MAX = maxf(res.range_MAX, c_range)
		
		res.max_energy_MIN = minf(res.max_energy_MIN, c_energy)
		res.max_energy_MAX = maxf(res.max_energy_MAX, c_energy)

	# Clean up edge cases dynamically 
	var props: Array[String] = ["max_hp", "max_shield", "speed", "agility", "damage", "range", "max_energy"]
	for prop in props:
		var min_val: float = res.get(prop + "_MIN")
		var max_val: float = res.get(prop + "_MAX")
		
		if min_val == INF:
			res.set(prop + "_MIN", 0.0)
		elif is_equal_approx(min_val, max_val):
			res.set(prop + "_MIN", 0.0)

	return res
