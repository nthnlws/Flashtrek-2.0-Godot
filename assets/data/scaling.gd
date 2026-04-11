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

# ─── Archetype Stat Multipliers ───────────────────────────────────────────────
enum ARCHETYPE { ESCORT, CRUISER, SCIENCE, FREIGHTER, RAIDER, DREADNOUGHT }

const ARCHETYPE_MULTIPLIERS: Dictionary = {
	ARCHETYPE.ESCORT:      { "MAX_HP": 0.7,  "MAX_SHIELD": 0.8,  "SPEED": 1.15,  "AGILITY": 1.15 },
	ARCHETYPE.CRUISER:     { "MAX_HP": 1.1,  "MAX_SHIELD": 1.1,  "SPEED": 1.0,  "AGILITY": 0.9 },
	ARCHETYPE.SCIENCE:     { "MAX_HP": 0.8,  "MAX_SHIELD": 1.2,  "SPEED": 1.1,  "AGILITY": 1.05 },
	ARCHETYPE.FREIGHTER:   { "MAX_HP": 1.3,  "MAX_SHIELD": 0.6,  "SPEED": 0.85,  "AGILITY": 0.8 },
	ARCHETYPE.RAIDER:      { "MAX_HP": 0.7,  "MAX_SHIELD": 0.7,  "SPEED": 1.25,  "AGILITY": 1.15 },
	ARCHETYPE.DREADNOUGHT: { "MAX_HP": 1.4,  "MAX_SHIELD": 1.3,  "SPEED": 0.75,  "AGILITY": 0.8 },
}

const FACTION_BIAS: Dictionary[Utility.FACTION, Dictionary] = {
	Utility.FACTION.FEDERATION: { "MAX_SHIELD": 1.15, "AGILITY": 0.95 },
	Utility.FACTION.KLINGON:    { "MAX_HP": 1.2,  "SPEED": 1.1,  "MAX_SHIELD": 0.85 },
	Utility.FACTION.ROMULAN:    { "SPEED": 1.1, "AGILITY": 1.1, "MAX_HP": 0.9 },
	Utility.FACTION.NEUTRAL:    {},
}

#One trait per ship set in the CSV. Changes gameplay behaviour, not raw stats.
enum SHIP_TRAIT {
		NONE,
		REGENERATING_SHIELDS,  # Shields regen faster out of combat
		HEAVY_WEAPONS,         # Torpedo damage multiplier
		CLOAKING_CAPABLE,      # Romulan ships — brief cloak ability
		CARGO_EXPANDED,        # Larger cargo hold
		RAPID_FIRE,            # Faster fire rate, lower per-shot damage
		POINT_DEFENSE,         # Chance to intercept incoming torpedoes
		}


# ─── Public API ───────────────────────────────────────────────────────────────

## Helper to convert index/total into the normalized 0.0-1.0 float used by this class.
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

static func apply_modifiers(base_val: float, scale: float,
							archetype: ARCHETYPE,
							faction: Utility.FACTION,
							stat_key: String) -> int:
	return roundi(base_val * scale
		* ARCHETYPE_MULTIPLIERS.get(archetype, {}).get(stat_key, 1.0)
		* FACTION_BIAS.get(faction, {}).get(stat_key, 1.0))

static func get_playable_stat_range(stat_key: String, scaled_stats: Dictionary) -> Vector2:
	var min_val: float = INF
	var max_val: float = -INF
	for entry: PlayableShipStats in scaled_stats.values():
		if not entry is PlayableShipStats:
			printerr("get_playable_stat_range: unexpected type in dict — ", type_string(typeof(entry)))
			continue
		var val: float = float(entry.get(stat_key))
		if val <= 0.0:
			continue
		min_val = minf(min_val, val)
		max_val = maxf(max_val, val)
	if min_val == INF or max_val == -INF:
		printerr("get_playable_stat_range: no valid values found for key '", stat_key, "' — returning zero range")
		return Vector2.ZERO
	return Vector2(min_val, max_val)


static func get_roster_stat_range(stat_key: String, is_move_stat: bool) -> Vector2:
	var min_val: float = INF
	var max_val: float = -INF
	var ships: Array = Utility.SHIP_DATA.values()
	var total: int = ships.size()
	
	for i: int in total:
		var t: float = get_norm_t(i, total)
		var base: float = float(ships[i].get(stat_key, 0))
		var scale: float = get_player_move_scale(t) if is_move_stat else get_player_stat_scale(t)
		
		var scaled_val: float = base * scale
		min_val = minf(min_val, base) # Min is at t=0
		max_val = maxf(max_val, scaled_val)
		
	return Vector2(min_val, max_val)

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
	var warp_ranges: Dictionary[int, int] = {
		0: 2,
		1: 2,
		2: 3,
		3: 4,
		4: 5,
		5: 6,
	}
	return warp_ranges.get(index, 1)


# ─── Spider Graph Normalisation ───────────────────────────────────────────────
static func get_faction_stat_range(unlock_list: Array[Utility.SHIP_TYPES], faction: Utility.FACTION) -> Dictionary:
	var ranges: Dictionary[String, Dictionary] = {
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
		var base: Dictionary    = Utility.SHIP_DATA[ship_type]
		var archetype: ARCHETYPE = base.ARCHETYPE
		var stat_mult: float    = get_player_stat_scale(t)
		var move_mult: float    = get_player_move_scale(t)
		var energy_scale: float = get_player_energy_scale(t)

		var computed: Dictionary[String, float] = {
			"max_hp":     apply_modifiers(base.MAX_HP,                   stat_mult, archetype, faction, "MAX_HP"),
			"max_shield": apply_modifiers(base.MAX_SHIELD,               stat_mult, archetype, faction, "MAX_SHIELD"),
			"speed":      apply_modifiers(base.PLAYER_SPEED_OVERRIDE,    move_mult, archetype, faction, "SPEED"),
			"agility":    apply_modifiers(base.PLAYER_AGILITY_OVERRIDE,  move_mult, archetype, faction, "AGILITY"),
			"damage":     apply_modifiers(1.0,                           stat_mult, archetype, faction, "DAMAGE"),
			"range":      float(get_ship_warp_range(i)),
			"max_energy": energy_scale,
		}

		for key in computed:
			ranges[key]["max"] = maxf(ranges[key]["max"], computed[key])
			ranges[key]["min"] = minf(ranges[key]["min"], computed[key])

	# Guard: if only one ship in list min == max, avoid zero-range issues downstream
	for key in ranges:
		if ranges[key]["min"] == INF:
			ranges[key]["min"] = 0.0
		if is_equal_approx(ranges[key]["min"], ranges[key]["max"]):
			ranges[key]["min"] = 0.0

	return ranges
