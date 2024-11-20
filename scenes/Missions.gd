extends Control

@onready var mission_label: RichTextLabel = %Mission_text
@onready var anim_player = $MarginContainer/AnimationPlayer

var showing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.missionAccepted.connect(_update_mission)
	
	mission_label.bbcode_text = "Mission: " + Utility.UI_yellow + "None[/color]"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("Tab"):
			if showing == false:
				anim_player.play("slide_out")
				showing = true
			elif showing == true:
				anim_player.play("slide_in")
				showing = false
	
	
	


func _update_mission(current_mission: Dictionary):
	if current_mission.is_empty():
		mission_label.text = "Mission: None"
		mission_label.custom_minimum_size.y = 20
	else:
		var mission_text = "Mission: " + Utility.UI_yellow +current_mission.get("mission_type", "Unknown") + "[/color]\n"
		mission_text += "Target System: " + Utility.UI_blue + current_mission.get("target_system", "Unknown") + "[/color]\n"
		mission_text += "Target Planet: " + Utility.UI_blue + current_mission.get("target_planet", "Unknown") + "[/color]\n"
		mission_text += "Cargo: " + Utility.UI_cargo_green + current_mission.get("cargo", "Unknown") + "[/color]"
		mission_label.bbcode_text = mission_text
		mission_label.custom_minimum_size.y = mission_label.get_line_count() * 30
