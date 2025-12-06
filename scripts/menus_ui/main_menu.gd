extends Control
class_name MainMenu

@export var mainGameScene:PackedScene

func _ready() -> void:
	%SinglePlayer.grab_focus()
	%Slot1.clicked.connect(_on_save_slot_pressed)
	%Slot2.clicked.connect(_on_save_slot_pressed)
	%Slot3.clicked.connect(_on_save_slot_pressed)


func _on_save_slot_pressed(node_name:String) -> void:
	match node_name:
		"Slot1":
			SaveManager.current_save_slot = 1
		"Slot2":
			SaveManager.current_save_slot = 2
		"Slot3":
			SaveManager.current_save_slot = 3
		_: printerr('No slot match found in main_menu.gd')
	#print('set saved slot to %s' % SaveManager.current_save_slot)
	
	LevelManager.create_or_load_galaxy(SaveManager.current_save_slot)
	get_tree().change_scene_to_packed(mainGameScene)
	

func _on_single_player_button_pressed(node_name:String) -> void:
	if %SlidingContainer.is_out:
		%SlidingContainer.slide_saves_container_in()
	else:
		%SlidingContainer.slide_saves_container_out()
	SignalBus.UIclickSound.emit()


func _on_exit_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	get_tree().quit()


func _on_credit_button_clicked(node_name:String) -> void:
	SignalBus.UIclickSound.emit()
	$Credits.visible = true
	$Credits.closeButton.grab_focus()

func _on_settings_button_pressed(node_name:String) -> void:
	SignalBus.UIclickSound.emit()
	$Settings.visible = true
	$Settings.closeButton.grab_focus()

func _on_credits_closed() -> void:
	$Credits.visible = false
	%SinglePlayer.grab_focus()

func _on_settings_closed() -> void:
	$Settings.visible = false
	%SinglePlayer.grab_focus()
