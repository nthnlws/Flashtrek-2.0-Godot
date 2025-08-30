extends TextureRect

@export var showing: bool = true
@export var transition_time:float = 0.8
const HIDDEN_POS:Vector2 = Vector2(0, -51)
const SHOWN_POS:Vector2 = Vector2.ZERO

var tween: Tween
var total_distance: float = 51

@onready var mission_text: RichTextLabel = %MissionText
@onready var fed_score: Label = %FedScore
@onready var klingon_score: Label = %KlingonScore
@onready var rom_score: Label = %RomScore

func _ready() -> void:
	SignalBus.missionAccepted.connect(_update_mission_text)
	SignalBus.reputationChanged.connect(_update_faction_score)
	SignalBus.finishMission.connect(_clear_mission_text)
	
	if showing == false:
		position = HIDDEN_POS
	
	mission_text.text = "Mission:"


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("Tab"):
			if showing:
				showing = false
				tween_menu(HIDDEN_POS)
			else:
				showing = true
				tween_menu(SHOWN_POS)


func _clear_mission_text() -> void:
	mission_text.text = "Mission:"


func _update_mission_text(mission_data:Dictionary) -> void:
	var fill_dict:Dictionary = {
		"planet": mission_data.planet,
		"system": mission_data.system,
	}
	var template_text: String = "Mission: [color=#6699CC]{planet}[/color] in [color=#FFCC66]{system}[/color] "
	var formatted_text: String = template_text.format(fill_dict)
	mission_text.text = formatted_text


func _update_faction_score(faction:Utility.FACTION, score:int) -> void:
	match faction:
		Utility.FACTION.FEDERATION:
			fed_score.text = str(score)
		Utility.FACTION.KLINGON:
			klingon_score.text = str(score)
		Utility.FACTION.ROMULAN:
			rom_score.text = str(score)


func tween_menu(target_position:Vector2) -> void: # Collapse mission menu
	# Stop running tween
	if is_instance_valid(tween):
		tween.kill()
	
	var distance_to_go = abs(position.distance_to(target_position))
	var travel_fraction = 0.0
	if total_distance > 0:
		travel_fraction = distance_to_go / total_distance
	var dynamic_duration = transition_time * travel_fraction
	
	tween = create_tween()
	tween.tween_property(self, "position", target_position, dynamic_duration)
