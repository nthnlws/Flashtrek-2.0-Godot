extends Control

# ─── MOCK BASE STATS ──────────────────────────────────────────────────────────
var base_stats: Dictionary = {
	"ARMOR": 100.0,
	"SHIELDS": 50.0,
	"SPEED": 300.0,
	"AGILITY": 70.0,
	"DAMAGE": 15.0
}

# ─── STATE VARIABLES ──────────────────────────────────────────────────────────
var current_tier: int = 1
var current_faction: int = Utility.FACTION.FEDERATION
var current_archetype: int = Scaling.ARCHETYPE.ESCORT
var test_additive_math: bool = false

# ─── SCENE NODE REFERENCES ────────────────────────────────────────────────────
@onready var spider_graph: SpiderGraph = %SpiderGraph
@onready var stats_label: RichTextLabel = %StatsLabel
@onready var tier_slider: HSlider = %TierSlider
@onready var faction_btn: OptionButton = %FactionButton
@onready var arch_btn: OptionButton = %ArchetypeButton
@onready var math_toggle: CheckBox = %MathToggle


func _ready() -> void:
	_connect_signals()
	_populate_option_buttons()
	update_calculations()


func _connect_signals() -> void:
	tier_slider.value_changed.connect(func(val: float): current_tier = int(val); update_calculations())
	faction_btn.item_selected.connect(func(idx: int): current_faction = faction_btn.get_item_id(idx); update_calculations())
	arch_btn.item_selected.connect(func(idx: int): current_archetype = arch_btn.get_item_id(idx); update_calculations())
	math_toggle.toggled.connect(func(toggled: bool): test_additive_math = toggled; update_calculations())


func _populate_option_buttons() -> void:
	for key in Utility.FACTION:
		faction_btn.add_item(key, Utility.FACTION[key])
	for key in Scaling.ARCHETYPE:
		arch_btn.add_item(key, Scaling.ARCHETYPE[key])


func update_calculations() -> void:
	var t: float = Scaling.get_norm_t(current_tier - 1, 6)
	var stat_scale: float = Scaling.get_player_stat_scale(t)
	var move_scale: float = Scaling.get_player_move_scale(t)

	var output := "[b]Current 't' Value:[/b] %.3f\n" % t
	output += "[b]Stat Curve Multiplier:[/b] %.3f\n" % stat_scale
	output += "[b]Move Curve Multiplier:[/b] %.3f\n\n" % move_scale
	output += "[b]Final Stats:[/b]\n"

	var graph_data: Dictionary[String, float] = {}

	for key: String in base_stats.keys():
		var base_val: float = base_stats[key]

		var scale_key := key
		if key == "ARMOR": scale_key = "MAX_HP"
		if key == "SHIELDS": scale_key = "MAX_SHIELD"

		var is_move: bool = (key == "SPEED" or key == "AGILITY")
		var curve_scale: float = move_scale if is_move else stat_scale
		var current_val := _calculate_stat(base_val, curve_scale, scale_key)

		var arch_mod: float = Scaling.ARCHETYPE_MULTIPLIERS.get(current_archetype as Scaling.ARCHETYPE, {}).get(scale_key, 1.0)
		var fact_mod: float = Scaling.FACTION_BIAS.get(current_faction as Utility.FACTION, {}).get(scale_key, 1.0)
		var effective_mult: float = float(current_val) / float(base_val)

		output += "- [color=cyan]%s[/color]: %d  [color=gray](Base: %d | Total Mult: %.2fx)[/color]\n" % [
			key, current_val, base_val, effective_mult
		]

		if test_additive_math:
			var am := arch_mod - 1.0
			var fm := fact_mod - 1.0
			var am_str = ("+" if am >= 0 else "") + "%.2f" % am
			var fm_str = ("+" if fm >= 0 else "") + "%.2f" % fm
			output += "   [color=gray][i]Math: Base * (Curve %.2f %s Arch %s Fact)[/i][/color]\n\n" % [curve_scale, am_str, fm_str]
		else:
			output += "   [color=gray][i]Math: Base * (Curve %.2f * Arch %.2f * Fact %.2f)[/i][/color]\n\n" % [curve_scale, arch_mod, fact_mod]

		var absolute_max_arch: float = _get_max_dict_val(Scaling.ARCHETYPE_MULTIPLIERS, scale_key)
		var absolute_max_fact: float = _get_max_dict_val(Scaling.FACTION_BIAS, scale_key)
		var absolute_max_scale: float = Scaling.PLAYER_MOVE_SCALE_MAX if is_move else Scaling.PLAYER_STAT_MAX

		var max_val := _calculate_theoretical(base_val, absolute_max_scale, absolute_max_arch, absolute_max_fact)
		var min_val := _calculate_theoretical(base_val, 1.0 if is_move else Scaling.PLAYER_STAT_MIN, 0.7, 0.8)

		var percent: float = 0.0
		if not is_equal_approx(min_val, max_val):
			percent = inverse_lerp(min_val, max_val, current_val)

		graph_data[key] = lerpf(0.2, 1.0, clampf(percent, 0.0, 1.0))

	var current_range := float(Scaling.get_ship_warp_range(current_tier - 1))
	graph_data["RANGE"] = lerpf(0.2, 1.0, current_range / 6.0)
	output += "- [color=cyan]RANGE     [/color]: %d\n" % int(current_range)

	stats_label.text = output
	spider_graph.set_all_values(graph_data)


func _calculate_stat(base_val: float, curve_scale: float, scale_key: String) -> int:
	var archetype := current_archetype as Scaling.ARCHETYPE
	var faction := current_faction as Utility.FACTION

	if not test_additive_math:
		return Scaling.apply_modifiers(base_val, curve_scale, archetype, faction, scale_key)
	else:
		var arch_mod: float = Scaling.ARCHETYPE_MULTIPLIERS.get(archetype, {}).get(scale_key, 1.0) - 1.0
		var fact_mod: float = Scaling.FACTION_BIAS.get(faction, {}).get(scale_key, 1.0) - 1.0
		var final_mult: float = maxf(curve_scale + arch_mod + fact_mod, 0.1)
		return roundi(base_val * final_mult)


func _calculate_theoretical(base_val: float, curve_scale: float, arch_mod: float, fact_mod: float) -> int:
	if not test_additive_math:
		return roundi(base_val * curve_scale * arch_mod * fact_mod)
	else:
		var final_mult: float = maxf(curve_scale + (arch_mod - 1.0) + (fact_mod - 1.0), 0.1)
		return roundi(base_val * final_mult)


func _get_max_dict_val(source_dict: Dictionary, stat_key: String) -> float:
	var highest := 1.0
	for sub_dict in source_dict.values():
		if sub_dict.has(stat_key):
			highest = maxf(highest, sub_dict[stat_key])
	return highest
