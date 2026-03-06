class_name Scaling
extends Resource

# ─── Constants ───────────────────────────────────────────────────────────────

const ENEMY_DIFF_MIN: float = 1.0
const ENEMY_DIFF_MAX: float = 5.0
const ENEMY_DIFF_EXP: float = 1.5

const PLAYER_STAT_MIN: float = 1.0
const PLAYER_STAT_MAX: float = 4.5
const PLAYER_SIG_MID: float = 0.4
const PLAYER_SIG_K: float = 5.0

const UNLOCK_COST_MIN: float = 2000.0
const UNLOCK_COST_MAX: float = 20000.0
const UNLOCK_COST_EXP: float = 2.0

# ─── Public API ───────────────────────────────────────────────────────────────

static func get_system_difficulty(sys_index: int, faction: Utility.FACTION) -> float:
	match sys_index:
		GalaxyData.SPECIAL_SYSTEMS.Solarus: return 1.0
		GalaxyData.SPECIAL_SYSTEMS.Kronos: return 2.8
		GalaxyData.SPECIAL_SYSTEMS.Romulus: return 5.0
		GalaxyData.SPECIAL_SYSTEMS.Risa: return 1.0
		_:
			return _enemy_curve(_galaxy_progress(sys_index, faction))

static func get_player_stat_scale(tier_index: int, total_ships: int) -> float:
	var t: float = float(tier_index) / float(max(total_ships - 1, 1))
	return _player_curve(t)


const PLAYER_MOVE_SCALE_MAX: float = 1.3  # 30% max improvement
static func get_player_move_scale(tier_index: int, total_ships: int) -> float:
	var t: float = float(tier_index) / float(max(total_ships - 1, 1))
	return 1.0 + (PLAYER_MOVE_SCALE_MAX - 1.0) * clampf(t, 0.0, 1.0)


static func get_unlock_cost_scale(tier_index: int, total_ships: int) -> float:
	var t: float = float(tier_index) / float(max(total_ships - 1, 1))
	var rounded_price: int = snappedi(_unlock_curve(t), 500)
	return rounded_price

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
	var s: float = 1.0 / (1.0 + exp(-PLAYER_SIG_K * (tc - PLAYER_SIG_MID)))
	var s_min: float = 1.0 / (1.0 + exp(-PLAYER_SIG_K * (0.0 - PLAYER_SIG_MID)))
	var s_max: float = 1.0 / (1.0 + exp(-PLAYER_SIG_K * (1.0 - PLAYER_SIG_MID)))
	return PLAYER_STAT_MIN + (PLAYER_STAT_MAX - PLAYER_STAT_MIN) * ((s - s_min) / (s_max - s_min))

static func _unlock_curve(t: float) -> float:
	return UNLOCK_COST_MIN + (UNLOCK_COST_MAX - UNLOCK_COST_MIN) * pow(clampf(t, 0.0, 1.0), UNLOCK_COST_EXP)
