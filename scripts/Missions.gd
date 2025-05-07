extends Control

@onready var mission_label: RichTextLabel = %Mission_text
@onready var mission_container: MarginContainer = $mission_container

var showing: bool = false


func _ready():
	SignalBus.missionAccepted.connect(_update_mission)
	SignalBus.entering_galaxy_warp.connect(close_menu)
	SignalBus.finishMission.connect(_reset_text)
	
	_reset_text()
	mission_container.position = Vector2(-275, 170)


func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("Tab"):
			if showing:
				close_menu()
			else: open_menu()


func _update_mission(current_mission: Dictionary):
	if current_mission.is_empty():
		_reset_text()
	else:
		var mission_text: String = "Mission: " + Utility.UI_yellow + current_mission.mission_type + "[/color]\n"
		mission_text += "Target System: " + Utility.UI_blue + current_mission.system + "[/color]\n"
		mission_text += "Target Planet: " + Utility.UI_blue + current_mission.planet + "[/color]\n"
		mission_text += "Cargo: " + Utility.UI_cargo_green + current_mission.cargo + "[/color]"
		mission_label.bbcode_text = mission_text
		mission_label.custom_minimum_size.y = mission_label.get_line_count() * 30

var current_tweens = []
func close_menu(): # Collapse mission menu
	# Stop all running tweens
	for tween in current_tweens:
		if tween.is_running():
			tween.stop()
			
	var tween_pos: Object = create_tween()
	tween_pos.tween_property(mission_container, "position", Vector2(-275, 170), 1.0)
	current_tweens.append(tween_pos)
	showing = false

func open_menu():
	var tween_pos: Object = create_tween()
	tween_pos.tween_property(mission_container, "position", Vector2(0, 170), 1.0)
	current_tweens.append(tween_pos)
	showing = true

func _reset_text():
	mission_label.bbcode_text = "Mission: " + Utility.UI_yellow + "None[/color]"
	mission_label.custom_minimum_size.y = 30
