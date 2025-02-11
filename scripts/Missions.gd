extends Control

@onready var mission_label: RichTextLabel = %Mission_text
@onready var mission_container: MarginContainer = $mission_container

var showing: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.missionAccepted.connect(_update_mission)
	SignalBus.entering_galaxy_warp.connect(close_menu)
	
	mission_label.bbcode_text = "Mission: " + Utility.UI_yellow + "None[/color]"
	mission_container.position = Vector2(-275, 170)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("Tab"):
			if showing:
				close_menu()
			else: open_menu()


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

var current_tweens = []
func close_menu(): # Expand or collapse mission menu
	# Stop all running tweens
	for tween in current_tweens:
		if tween.is_running():
			tween.stop()
			
	var tween_pos = create_tween()
	tween_pos.tween_property(mission_container, "position", Vector2(-275, 170), 1.0)
	current_tweens.append(tween_pos)
	showing = false

func open_menu():
	var tween_pos = create_tween()
	tween_pos.tween_property(mission_container, "position", Vector2(0, 170), 1.0)
	current_tweens.append(tween_pos)
	showing = true
