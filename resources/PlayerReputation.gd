extends Resource
class_name PlayerReputation

signal reputation_total_changed(effected_faction: Utility.FACTION, new_total: float)

@export_group("Faction Reputation")
@export var FederationRep: float = 0.0
@export var KlingonRep: float = 0.0
@export var RomulanRep: float = 0.0
@export var NeutralRep: float = 0.0

const NEUTRAL_THRESHOLD: int = 5000 # Any faction rep above this value is no longer neutral
const ENEMY_FACTION_MULTIPLIER: float = 0.50 # Amount the opposite faction rep decreases
const MAX_REP_VALUE: float = 100000.0
const DEATH_PENALTY = 0.1 # Rep penalty for death in percentage

func _init() -> void:
	SignalBus.reputation_change_triggered.connect(_handle_reputation_change)
	SignalBus.playerRespawned.connect(_handle_player_death)


func get_reputation(faction: Utility.FACTION) -> float:
		if faction == Utility.FACTION.FEDERATION:
			return FederationRep
		elif faction == Utility.FACTION.KLINGON:
			return KlingonRep
		elif faction == Utility.FACTION.ROMULAN:
			return RomulanRep
		else: return NeutralRep


func update_all_scores() -> void:
	reputation_total_changed.emit(Utility.FACTION.FEDERATION, FederationRep)
	reputation_total_changed.emit(Utility.FACTION.KLINGON, KlingonRep)
	reputation_total_changed.emit(Utility.FACTION.ROMULAN, RomulanRep)


func _handle_reputation_change(faction: Utility.FACTION, changed_amount: float) -> void:
	if faction == Utility.FACTION.FEDERATION:
		FederationRep = _clamp_rep(FederationRep + changed_amount, Utility.FACTION.FEDERATION)
		KlingonRep    = _clamp_rep(KlingonRep - (changed_amount * ENEMY_FACTION_MULTIPLIER), Utility.FACTION.KLINGON)
		reputation_total_changed.emit(faction, FederationRep)
		reputation_total_changed.emit(Utility.FACTION.KLINGON, KlingonRep)
	elif faction == Utility.FACTION.KLINGON:
		KlingonRep  = _clamp_rep(KlingonRep + changed_amount, Utility.FACTION.KLINGON)
		RomulanRep  = _clamp_rep(RomulanRep - (changed_amount * ENEMY_FACTION_MULTIPLIER), Utility.FACTION.ROMULAN)
		reputation_total_changed.emit(faction, KlingonRep)
		reputation_total_changed.emit(Utility.FACTION.ROMULAN, RomulanRep)
	elif faction == Utility.FACTION.ROMULAN:
		RomulanRep    = _clamp_rep(RomulanRep + changed_amount, Utility.FACTION.ROMULAN)
		FederationRep = _clamp_rep(FederationRep - (changed_amount * ENEMY_FACTION_MULTIPLIER), Utility.FACTION.FEDERATION)
		reputation_total_changed.emit(faction, RomulanRep)
		reputation_total_changed.emit(Utility.FACTION.FEDERATION, FederationRep)
	elif faction == Utility.FACTION.NEUTRAL:
			NeutralRep = _clamp_rep(NeutralRep + changed_amount, Utility.FACTION.NEUTRAL)
			reputation_total_changed.emit(faction, NeutralRep)


func _clamp_rep(value: float, faction: Utility.FACTION) -> float:
	var clamped: float = clampf(value, -MAX_REP_VALUE, MAX_REP_VALUE)
	if clamped != value:
		push_warning("Reputation clamped for %s: %.0f → %.0f (limit ±%.0f)" % [
			Utility.FACTION.keys()[faction], value, clamped, MAX_REP_VALUE
		])
	return clamped
 

func _handle_player_death() -> void:
	if FederationRep > 0:
		FederationRep = snappedi(FederationRep * (1 - DEATH_PENALTY), 1)
		reputation_total_changed.emit(Utility.FACTION.FEDERATION, FederationRep)
	if KlingonRep > 0:
		KlingonRep = snappedi(KlingonRep * (1 - DEATH_PENALTY), 1)
		reputation_total_changed.emit(Utility.FACTION.KLINGON, KlingonRep)
	if RomulanRep > 0:
		RomulanRep = snappedi(RomulanRep * (1 - DEATH_PENALTY), 1)
		reputation_total_changed.emit(Utility.FACTION.ROMULAN, RomulanRep)
	if NeutralRep > 0:
		NeutralRep = snappedi(NeutralRep * (1 - DEATH_PENALTY), 1)
		reputation_total_changed.emit(Utility.FACTION.NEUTRAL, NeutralRep)
