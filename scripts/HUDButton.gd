extends Control

@onready var scale_nodes = [$Quad1, $Quad2, $Quad3, $Quad4, $Center, $TextureRect]

var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

const HIGH:float = 2.0
const LOW:float = 0.5


var button_array = []


func _ready():
	manual_scale(0.7)
	SignalBus.HUDchanged.connect(manual_scale)
	
	#Connect Input signals from HUD buttons
	button_array = get_tree().get_nodes_in_group("HUD_button")
	for button in button_array:
		button.gui_input.connect(handle_button_click.bind(button))
#
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()
#
#
func handle_button_click(event, button):
	if event.is_action_pressed("left_click"):
		var signal_name = button.name + "_clicked"
		if SignalBus.has_signal(signal_name):
			SignalBus.emit_signal(signal_name)
			#print(str(signal_name) + " emitted")
			play_click_sound(LOW)
		else: print("No button signal found")


func manual_scale(new_scale):
	var use = Vector2(new_scale, new_scale)
	scale = use * Vector2(0.4, 0.4)
	
	
func scale_HUD_button(new_scale): # Scales entire Control node, not used
	scale = Vector2(new_scale, new_scale)
	
	
func play_click_sound(volume): 
	var sound_array_length = sound_array.size() - 1
	var default_db = sound_array[sound_array_location].volume_db
	var effective_volume = default_db / volume
	
	match sound_array_location:
		sound_array_length: # When location in array = array size, shuffle array and reset location
			#sound_array[sound_array_location].volume_db = effective_volume
			sound_array[sound_array_location].play()
			#sound_array[sound_array_location].volume_db = default_db
			sound_array.shuffle()
			sound_array_location = 0
		_: # Runs for all array values besides last
			#sound_array[sound_array_location].volume_db = effective_volume
			sound_array[sound_array_location].play()
			#sound_array[sound_array_location].volume_db = default_db
			sound_array_location += 1
