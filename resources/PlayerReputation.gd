extends Resource
class_name PlayerReputation

signal player_faction_changed(new_faction: Utility.FACTION)
signal reputation_total_changed(effected_faction: Utility.FACTION, new_total: float)

@export_group("Faction Reputation")
@export var FederationRep: float = 0.0
@export var KlingonRep: float = 0.0
@export var RomulanRep: float = 0.0
@export var NeutralRep: float = 0.0

@export var current_player_faction: Utility.FACTION = Utility.FACTION.NEUTRAL
const NEUTRAL_THRESHOLD: int = 5000 # Any faction rep above this value is no longer neutral
const ENEMY_FACTION_MULTIPLIER: float = 0.50 # Amount the opposite faction rep decreases

func _init() -> void:
	SignalBus.reputation_change_triggered.connect(_handle_reputation_change)


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
	#print("new rep: %s for faction %s" % [changed_amount, faction])
	match faction:
		Utility.FACTION.FEDERATION:
			FederationRep = FederationRep + changed_amount
			KlingonRep = KlingonRep - (changed_amount * ENEMY_FACTION_MULTIPLIER)
			reputation_total_changed.emit(faction, FederationRep)
			reputation_total_changed.emit(Utility.FACTION.KLINGON, KlingonRep)
		Utility.FACTION.KLINGON:
			KlingonRep = KlingonRep + changed_amount
			RomulanRep = RomulanRep - (changed_amount * ENEMY_FACTION_MULTIPLIER)
			reputation_total_changed.emit(faction, KlingonRep)
			reputation_total_changed.emit(Utility.FACTION.ROMULAN, RomulanRep)
		Utility.FACTION.ROMULAN:
			RomulanRep = RomulanRep + changed_amount
			FederationRep = FederationRep - (changed_amount * ENEMY_FACTION_MULTIPLIER)
			reputation_total_changed.emit(faction, RomulanRep)
			reputation_total_changed.emit(Utility.FACTION.FEDERATION, FederationRep)
		Utility.FACTION.NEUTRAL:
			NeutralRep = NeutralRep + changed_amount
		_:
			push_error("Unknown faction in PlayerReputation manager")
	
	var new_faction: Utility.FACTION = get_current_faction()
	if new_faction != current_player_faction:
		current_player_faction = new_faction
		player_faction_changed.emit(new_faction)


func get_current_faction() -> Utility.FACTION:
	var highest_val: float = max(FederationRep, KlingonRep, RomulanRep)
	
	if highest_val <= NEUTRAL_THRESHOLD:
		return Utility.FACTION.NEUTRAL
	
	if highest_val == FederationRep: return Utility.FACTION.FEDERATION
	if highest_val == KlingonRep: return Utility.FACTION.KLINGON
	if highest_val == RomulanRep: return Utility.FACTION.ROMULAN
	
	return Utility.FACTION.NEUTRAL
