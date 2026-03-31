extends Control
class_name MainMenu

@export var mainGameScene:PackedScene
@export var settings: Control
@export var credits: Control

func _ready() -> void:
	%SinglePlayer.grab_focus()
	
	AudioManager.play_music(true)


func _on_save_slot_pressed(node_name:String) -> void:
	match node_name:
		"Slot1":
			SaveManager.current_save_slot = 1
		"Slot2":
			SaveManager.current_save_slot = 2
		"Slot3":
			SaveManager.current_save_slot = 3
		_: printerr('No slot "%s" match found in main_menu.gd' % node_name)
	#print('set saved slot to %s' % SaveManager.current_save_slot)
	
	LevelManager.create_or_load_galaxy(SaveManager.current_save_slot)
	get_tree().change_scene_to_packed(mainGameScene)


func _on_save_slot_selected_for_delete(node_name:String) -> void:
	%PopupContainer.open_popup(node_name)


func _on_save_slot_deleted(node_name:String) -> void:
	match node_name:
		"Slot1":
			SaveManager.delete_save(1)
		"Slot2":
			SaveManager.delete_save(2)
		"Slot3":
			SaveManager.delete_save(3)
		_: printerr('No slot number "%s" found to delete' % node_name)


func _on_single_player_button_pressed(node_name:String) -> void:
	if %SlidingContainer.is_out:
		%SlidingContainer.slide_saves_container_in()
		if %SlidingContainer.in_management_state: # Turn off management state if true
			%SlidingContainer._toggle_management_state()
	else:
		%SlidingContainer.slide_saves_container_out()
	AudioManager.play_UI_click_sound()


func _on_exit_button_pressed(node_name:String) -> void:
	AudioManager.play_UI_click_sound()
	get_tree().quit()


func _on_credit_button_clicked(node_name:String) -> void:
	AudioManager.play_UI_click_sound()
	credits.close_button.grab_focus()
	credits.visible = true

func _on_settings_button_pressed(node_name:String) -> void:
	AudioManager.play_UI_click_sound()
	settings.visible = true
	settings.close_button.grab_focus()

func _on_credits_closed() -> void:
	credits.visible = false
	%SinglePlayer.grab_focus()

func _on_settings_closed() -> void:
	settings.visible = false
	%SinglePlayer.grab_focus()


func _on_delete_all_saves_tab_clicked(node_name: String) -> void:
	SaveManager.delete_save(1)
	SaveManager.delete_save(2)
	SaveManager.delete_save(3)
	#print("all saves deleted")
