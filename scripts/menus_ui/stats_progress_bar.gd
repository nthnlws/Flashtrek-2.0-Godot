extends Control
class_name StatsBar

@onready var progress: ProgressBar = $ProgressBar

#var faction_colors: Dictionary[Utility.FACTION, Color] = {
	#Utility.FACTION.FEDERATION: Color("ff9a66"),
	#Utility.FACTION.KLINGON: Color("581316"),
	#Utility.FACTION.ROMULAN: Color("38948a"),
	#Utility.FACTION.NEUTRAL: Color("ffffff"),
#}

func set_progress(percentage: float) -> void:
	#print("set %s to %0.2f" % [self.name, percentage])
	progress.value = percentage

#func set_faction(faction: Utility.FACTION) -> void:
	#$Frame.self_modulate = faction_colors[faction]
