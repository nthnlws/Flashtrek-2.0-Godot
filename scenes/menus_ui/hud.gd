extends Control

@onready var fed_score: Label = %FedScore
@onready var klingon_score: Label = %KlingonScore
@onready var rom_score: Label = %RomScore


func _ready() -> void:
	SignalBus.reputationChanged.connect(_update_faction_score)


func _update_faction_score(faction:Utility.FACTION, score:int) -> void:
	match faction:
		Utility.FACTION.FEDERATION:
			fed_score.text = str(score)
		Utility.FACTION.KLINGON:
			klingon_score.text = str(score)
		Utility.FACTION.ROMULAN:
			rom_score.text = str(score)
