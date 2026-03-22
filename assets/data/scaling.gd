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
# Redistributes the scaling budget to give each ship role a distinct stat shape.
enum ARCHETYPE { ESCORT, CRUISER, SCIENCE, FREIGHTER, RAIDER, DREADNOUGHT }

const ARCHETYPE_MULTIPLIERS: Dictionary = {
	ARCHETYPE.ESCORT:      { "MAX_HP": 0.7,  "MAX_SHIELD": 0.8,  "SPEED": 1.4,  "ROTATION_SPEED": 1.5 },
	ARCHETYPE.CRUISER:     { "MAX_HP": 1.1,  "MAX_SHIELD": 1.1,  "SPEED": 1.0,  "ROTATION_SPEED": 0.9 },
	ARCHETYPE.SCIENCE:     { "MAX_HP": 0.8,  "MAX_SHIELD": 1.3,  "SPEED": 1.1,  "ROTATION_SPEED": 1.1 },
	ARCHETYPE.FREIGHTER:   { "MAX_HP": 1.3,  "MAX_SHIELD": 0.6,  "SPEED": 0.7,  "ROTATION_SPEED": 0.6 },
	ARCHETYPE.RAIDER:      { "MAX_HP": 0.6,  "MAX_SHIELD": 0.7,  "SPEED": 1.6,  "ROTATION_SPEED": 1.6 },
	ARCHETYPE.DREADNOUGHT: { "MAX_HP": 1.5,  "MAX_SHIELD": 1.4,  "SPEED": 0.7,  "ROTATION_SPEED": 0.6 },
}

# ─── Faction Stat Bias ────────────────────────────────────────────────────────
# Small faction-wide modifiers, applied on top of archetype multipliers.
const FACTION_BIAS: Dictionary = {
	Utility.FACTION.FEDERATION: { "MAX_SHIELD": 1.15, "ROTATION_SPEED": 0.95 },
	Utility.FACTION.KLINGON:    { "MAX_HP": 1.2,  "SPEED": 1.1,  "MAX_SHIELD": 0.85 },
	Utility.FACTION.ROMULAN:    { "SPEED": 1.15, "ROTATION_SPEED": 1.15, "MAX_HP": 0.9 },
	Utility.FACTION.NEUTRAL:    {},
}

# ─── Ship Traits ──────────────────────────────────────────────────────────────
# One trait per ship set in the CSV. Changes gameplay behaviour, not raw stats.
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

static func get_archetype_multiplier(archetype: ARCHETYPE, stat_key: String) -> float:
	return ARCHETYPE_MULTIPLIERS.get(archetype, {}).get(stat_key, 1.0)

static func get_faction_bias(faction: Utility.FACTION, stat_key: String) -> float:
	return FACTION_BIAS.get(faction, {}).get(stat_key, 1.0)

static func get_playable_stat_range(stat_key: String, scaled_stats: Dictionary) -> Vector2:
	var min_val: float = INF
	var max_val: float = -INF
	for entry: Dictionary in scaled_stats.values():
		var val: float = float(entry.get(stat_key, 0))
		if val <= 0.0:
			continue
		min_val = minf(min_val, val)
		max_val = maxf(max_val, val)
	return Vector2(min_val, max_val)

static func apply_modifiers(base_val: float, scale: float,
							archetype: ARCHETYPE,
							faction: Utility.FACTION,
							stat_key: String) -> int:
		return roundi(base_val * scale
			* get_archetype_multiplier(archetype, stat_key)
			* get_faction_bias(faction, stat_key))

static func get_roster_stat_range(stat_key: String, is_move_stat: bool) -> Vector2:
	var min_val: float = INF
	var max_val: float = -INF
	var ships: Array = Utility.SHIP_DATA.values()
	var total: int = ships.size()
	for i: int in total:
		var base: float = float(ships[i].get(stat_key, 0))
		var min_scaled: float = base
		var max_scaled: float = base * (get_player_move_scale(total - 1, total) if is_move_stat else get_player_stat_scale(total - 1, total))
		min_val = minf(min_val, min_scaled)
		max_val = maxf(max_val, max_scaled)
	return Vector2(min_val, max_val)

static func get_system_difficulty(sys_index: int, faction: Utility.FACTION) -> float:
	match sys_index:
		GalaxyData.SPECIAL_SYSTEMS.Solarus: return 1.0
		GalaxyData.SPECIAL_SYSTEMS.Kronos:  return 2.8
		GalaxyData.SPECIAL_SYSTEMS.Romulus: return 5.0
		GalaxyData.SPECIAL_SYSTEMS.Risa:    return 1.0
		_:
			return _enemy_curve(_galaxy_progress(sys_index, faction))

static func get_player_stat_scale(tier_index: int, total_ships: int) -> float:
	var t: float = float(tier_index) / float(max(total_ships - 1, 1))
	return _player_curve(t)

static func get_player_move_scale(tier_index: int, total_ships: int) -> float:
	var t: float = float(tier_index) / float(max(total_ships - 1, 1))
	return 1.0 + (PLAYER_MOVE_SCALE_MAX - 1.0) * clampf(t, 0.0, 1.0)

static func get_unlock_cost_scale(tier_index: int, total_ships: int) -> int:
	var t: float = float(tier_index) / float(max(total_ships - 1, 1))
	return snappedi(_unlock_curve(t), 500)

# ─── Private Curves ───────────────────────────────────────────────────────────

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
