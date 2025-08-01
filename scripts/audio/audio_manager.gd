extends Node


func _ready() -> void:
	SignalBus.UIselectSound.connect(play_UI_select_sound)
	SignalBus.UIclickSound.connect(play_UI_click_sound)
	
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()


@onready var button_select: AudioStreamPlayer = %Button_select
func play_UI_select_sound() -> void:
	button_select.play()


var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0
func play_UI_click_sound() -> void: 
	var sound_array_length: int = sound_array.size() - 1
	sound_array[sound_array_location].stop() # Ensure the sound is stopped before playing
	sound_array[sound_array_location].play()

	match sound_array_location:
		sound_array_length: # When location is last in array, shuffle and reset location
			sound_array.shuffle()
			sound_array_location = 0
		_: # Runs for all array values besides last
			sound_array_location += 1
