extends Resource
class_name PlayerReputation

@export_group("Faction Reputation")
@export var FederationRep: float = 0
@export var KlingonRep: float = 0
@export var RomulanRep: float = 0
@export var NeutralRep: float = 0

func _init() -> void:
	SignalBus.reputationChanged.connect(_handle_reputation_change)


func _handle_reputation_change(faction:Utility.FACTION, new_value: float):
	#print("new rep: %s for faction %s" % [new_value, faction])
	match faction:
		Utility.FACTION.FEDERATION:
			FederationRep = new_value
		Utility.FACTION.KLINGON:
			KlingonRep = new_value
		Utility.FACTION.ROMULAN:
			RomulanRep = new_value
		Utility.FACTION.NEUTRAL:
			NeutralRep = new_value
		_:
			push_error("Unknown faction")
