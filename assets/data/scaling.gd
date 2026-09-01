@tool
class_name Scaling
extends Resource

# ─── Enemy Scaling Constants ──────────────────────────────────────────────────
const ENEMY_DIFF_MIN: float = 1.0
const ENEMY_DIFF_MAX: float = 5.0
const ENEMY_DIFF_EXP: float = 1.5

# ─── Player Stat Scaling Constants ───────────────────────────────────────────
const PLAYER_STAT_MIN: float = 1.0
const PLAYER_STAT_MAX: float = 4.5
const PLAYER_SIG_MID: float = 0.4
const PLAYER_SIG_K: float = 5.0
const PLAYER_MOVE_SCALE_MAX: float = 1.2

# ─── Unlock Cost Constants ────────────────────────────────────────────────────
const UNLOCK_COST_MIN: float = 2000.0
const UNLOCK_COST_MAX: float = 20000.0
const UNLOCK_COST_EXP: float = 2.0

# ─── Archetype Stat Multipliers ─────
enum ARCHETYPE { ESCORT, CRUISER, SCIENCE, FREIGHTER, RAIDER, DREADNOUGHT, NONE }

const ARCHETYPE_MULTIPLIERS: Dictionary = {
	ARCHETYPE.ESCORT:      { "MAX_HP": 0.85, "MAX_SHIELD": 0.9,  "SPEED": 1.1,  "AGILITY": 1.1 }, 
	ARCHETYPE.CRUISER:     { "MAX_HP": 1.05, "MAX_SHIELD": 1.05, "SPEED": 1.0,  "AGILITY": 1.0 },
	ARCHETYPE.SCIENCE:     { "MAX_HP": 0.9,  "MAX_SHIELD": 1.1,  "SPEED": 1.05, "AGILITY": 1.05 },
	ARCHETYPE.FREIGHTER:   { "MAX_HP": 1.15, "MAX_SHIELD": 0.85, "SPEED": 0.9,  "AGILITY": 0.9 },
	ARCHETYPE.RAIDER:      { "MAX_HP": 0.85, "MAX_SHIELD": 0.85, "SPEED": 1.15, "AGILITY": 1.1 },
	ARCHETYPE.DREADNOUGHT: { "MAX_HP": 1.2,  "MAX_SHIELD": 1.15, "SPEED": 0.85, "AGILITY": 0.85 },
}

const FACTION_BIAS: Dictionary = {
	Utility.FACTION.FEDERATION: { "MAX_SHIELD": 1.15, "AGILITY": 0.95 },
	Utility.FACTION.KLINGON:    { "MAX_HP": 1.2,  "SPEED": 1.1,  "MAX_SHIELD": 0.85 },
	Utility.FACTION.ROMULAN:    { "SPEED": 1.1, "AGILITY": 1.1, "MAX_HP": 0.9 },
	Utility.FACTION.NEUTRAL:    {},
}

enum SHIP_TRAIT {
	NONE,
	REGENERATING_SHIELDS,	# Shields regen faster out of combat
	HEAVY_WEAPONS,			# Torpedo damage multiplier   
	CLOAKING_CAPABLE,		# Cloak ability
	CARGO_EXPANDED,			# Larger cargo hold
	RAPID_FIRE,				# Faster fire rate, lower per-shot damage
	POINT_DEFENSE,			# Chance to intercept incoming torpedoes
}

# ─── Public API ───────────────────────────────────────────────────────────────

static func get_norm_t(index: int, total: int) -> float:
	if total <= 1: return 0.0
	return clampf(float(index) / float(total - 1), 0.0, 1.0)

static func get_player_stat_scale(t: float) -> float:
	return _player_curve(t)

static func get_player_move_scale(t: float) -> float:
	return 1.0 + (PLAYER_MOVE_SCALE_MAX - 1.0) * clampf(t, 0.0, 1.0)

static func get_unlock_cost_scale(t: float) -> int:
	return snappedi(_unlock_curve(t), 500)

static func get_player_energy_scale(t: float) -> float:
	return lerpf(1.0, 3.0, clampf(t, 0.0, 1.0))

# Changed return type to float so damage modifiers don't lose precision
static func apply_modifiers(base_val: float, scale: float, archetype: ARCHETYPE, faction: Utility.FACTION, stat_key: String) -> float:
	var arch_mod: float = ARCHETYPE_MULTIPLIERS.get(archetype, {}).get(stat_key, 1.0) - 1.0
	var fact_mod: float = FACTION_BIAS.get(faction, {}).get(stat_key, 1.0) - 1.0
	var final_mult: float = scale + arch_mod + fact_mod
	final_mult = maxf(final_mult, 0.1) 
	
	return base_val * final_mult


static func get_system_difficulty(sys_index: int, faction: Utility.FACTION) -> float:
	match sys_index:
		GalaxyData.SPECIAL_SYSTEMS.Solarus: return 1.0
		GalaxyData.SPECIAL_SYSTEMS.Kronos:  return 2.8
		GalaxyData.SPECIAL_SYSTEMS.Romulus: return 5.0
		GalaxyData.SPECIAL_SYSTEMS.Risa:    return 1.0
		_:
			return _enemy_curve(_galaxy_progress(sys_index, faction))

# ─── Private Curves ────
static func _galaxy_progress(sys_index: int, faction: Utility.FACTION) -> float:
	match faction:
		Utility.FACTION.FEDERATION:
			return (float(sys_index) / GalaxyData.NUM_FED_SYSTEMS) * 0.333
		Utility.FACTION.KLINGON:
			return 0.333 + (float(sys_index) / GalaxyData.NUM_ROM_SYSTEMS) * 0.333
		Utility.FACTION.ROMULAN:
			return 0.666 + (float(sys_index) / GalaxyData.NUM_KLING_SYSTEMS) * 0.334
		_: return 1.0

static func _enemy_curve(t: float) -> float:
	return ENEMY_DIFF_MIN + (ENEMY_DIFF_MAX - ENEMY_DIFF_MIN) * pow(clampf(t, 0.0, 1.0), ENEMY_DIFF_EXP)

static func _player_curve(t: float) -> float:
	var tc: float = clampf(t, 0.0, 1.0)
	var s: float = 1.0 / (1.0 + exp(-PLAYER_SIG_K * (tc  - PLAYER_SIG_MID)))
	var s_min: float = 1.0 / (1.0 + exp(-PLAYER_SIG_K * (0.0 - PLAYER_SIG_MID)))
	var s_max: float = 1.0 / (1.0 + exp(-PLAYER_SIG_K * (1.0 - PLAYER_SIG_MID)))
	return PLAYER_STAT_MIN + (PLAYER_STAT_MAX - PLAYER_STAT_MIN) * ((s - s_min) / (s_max - s_min))

static func _unlock_curve(t: float) -> float:
	return UNLOCK_COST_MIN + (UNLOCK_COST_MAX - UNLOCK_COST_MIN) * pow(clampf(t, 0.0, 1.0), UNLOCK_COST_EXP)

static func get_ship_warp_range(index:int) -> int:
	var warp_ranges: Dictionary = {
		0: 2, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6,
	}
	return warp_ranges.get(index, 1)

# ─── Spider Graph Normalisation ───────────────────────────────────────────────
static func get_faction_stat_range(unlock_list: Array[Utility.SHIP_TYPES], faction: Utility.FACTION) -> Dictionary:
	var ranges: Dictionary = {
		"max_hp":     { "min": INF, "max": 0.0 },
		"max_shield": { "min": INF, "max": 0.0 },
		"speed":      { "min": INF, "max": 0.0 },
		"agility":    { "min": INF, "max": 0.0 },
		"damage":     { "min": INF, "max": 0.0 },
		"range":      { "min": INF, "max": 0.0 },
		"max_energy": { "min": INF, "max": 0.0 },
	}

	var total: int = unlock_list.size()
	for i: int in total:
		var t: float            = get_norm_t(i, total)
		var ship_type           = unlock_list[i]
		var base: BaseShipInfo    = Utility.get_ship_stats(ship_type)
		var archetype: ARCHETYPE = base.ARCHETYPE
		var stat_mult: float    = get_player_stat_scale(t)
		var move_mult: float    = get_player_move_scale(t)
		var energy_scale: float = get_player_energy_scale(t)

		var computed: Dictionary = {
			"max_hp":     apply_modifiers(base.base_HP,                    stat_mult, archetype, faction, "MAX_HP"),
			"max_shield": apply_modifiers(base.base_shield,                stat_mult, archetype, faction, "MAX_SHIELD"),
			"speed":      apply_modifiers(base.base_speed,    				move_mult, archetype, faction, "SPEED"),
			"agility":    apply_modifiers(base.base_agility,  				move_mult, archetype, faction, "AGILITY"),
			"damage":     apply_modifiers(1.0,                            stat_mult, archetype, faction, "DAMAGE"),
			"range":      float(get_ship_warp_range(i)),
			"max_energy": snappedi(150.0 * energy_scale, 25),
		}

		for key in computed:
			ranges[key]["max"] = maxf(ranges[key]["max"], computed[key])
			ranges[key]["min"] = minf(ranges[key]["min"], computed[key])

	for key in ranges:
		if ranges[key]["min"] == INF:
			ranges[key]["min"] = 0.0
		if is_equal_approx(ranges[key]["min"], ranges[key]["max"]):
			ranges[key]["min"] = 0.0

	return ranges

static func get_spider_norm(current_val: float, stat_key: String) -> float:
	var global_max: float = 1.0
	var global_min: float = 1.0
	
	if stat_key in ["SPEED", "AGILITY"]:
		global_max = 1.0 * PLAYER_MOVE_SCALE_MAX * 1.15
		global_min = 1.0 * 1.0 * 0.8
	else:
		global_max = 1.0 * PLAYER_STAT_MAX * 1.2
		global_min = 1.0 * 1.0 * 0.7
		
	return clampf(inverse_lerp(global_min, global_max, current_val), 0.15, 1.0)
