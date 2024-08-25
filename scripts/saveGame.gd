extends Node


func _ready():
	SignalBus.saveGame = self
	
	
#func _on_game_reset():
	#save_menu_state()
	
	
#func _unhandled_input(event):
	#if Input.is_action_just_pressed("save"):
		#save_menu_state()
	#if Input.is_action_just_pressed("load"):
		#load_menu_status()

	
func load_menu_status():
	if not FileAccess.file_exists("user://menuoptions.json"):
		print("No save file found")
		# TODO: default menu file
		return
	
	var file = FileAccess.open("user://menuoptions.json", FileAccess.READ)
	var json = file.get_as_text()
	var save_data = JSON.parse_string(json)
	
	for key in save_data.keys():
		GameSettings.set(key, save_data[key])
		
	file.close()
