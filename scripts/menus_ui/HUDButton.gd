extends Control

@onready var scale_nodes: Array[Node] = [$Quad1, $Quad2, $Quad3, $Quad4, $Center, $TextureRect]

var sound_array:Array[Node] = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

const HIGH:float = 2.0
const LOW:float = 0.5

var button_array: Array[Node] = []


func _ready() -> void:
	manual_scale(0.7)
	SignalBus.HUDchanged.connect(manual_scale)
	
	#Connect Input signals from HUD buttons
	button_array = get_tree().get_nodes_in_group("HUD_button")
	for button: TextureButton in button_array:
		button.gui_input.connect(handle_button_click.bind(button))
#
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()
#
#
func handle_button_click(event: InputEvent, button: TextureButton) -> void:
	if event.is_action_pressed("left_click") and Utility.mainScene.in_galaxy_warp == false:
		var signal_name: String = button.name + "_clicked"
		if SignalBus.has_signal(signal_name):
			SignalBus.emit_signal(signal_name)
			#print(str(signal_name) + " emitted")
			Utility.play_click_sound(0)
		else: print("No button signal found")

func manual_scale(new_scale: float) -> void:
	var use: Vector2 = Vector2(new_scale, new_scale)
	scale = use * Vector2(0.4, 0.4)
	
	
func scale_HUD_button(new_scale: float) -> void: # Scales entire Control node, not used
	scale = Vector2(new_scale, new_scale)
	
