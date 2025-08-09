extends Control

@onready var label_button_array: Array[Node] = get_tree().get_nodes_in_group("label_buttons")
@onready var texture_button_array: Array[Node] = get_tree().get_nodes_in_group("texture_buttons")
@onready var animation_players: Array[Node] = get_tree().get_nodes_in_group("anims")

var sound_array:Array[Node] = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

const HIGH:float = 2.0
const LOW:float = 0.5

func _input(event: InputEvent) -> void:
	if get_tree().get_current_scene().name == "HUD_button" and event is InputEventKey:
		_handle_debug_inputs(event)


func _ready() -> void:
	_connect_signals()
	manual_scale(0.7)
	
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()


func _connect_signals():
	SignalBus.toggleQ2HUD.connect(_handle_beam_animation)
	SignalBus.toggleQ3HUD.connect(_handle_hail_animation)
	SignalBus.toggleQ4HUD.connect(_handle_dock_animation)
	SignalBus.HUDchanged.connect(manual_scale)
	
	for button in label_button_array:
		button.button_pressed.connect(_handle_button_click.bind(button.name))
	for button in texture_button_array:
		button.pressed.connect(_handle_button_click.bind(button.name))


func _handle_button_click(button_name: String) -> void:
	if Navigation.in_galaxy_warp == false:
		SignalBus.UIclickSound.emit()
		var signal_name: String = button_name + "_clicked"
		if SignalBus.has_signal(signal_name):
			SignalBus.emit_signal(signal_name)
			#print(str(signal_name) + " emitted")
		else: print("%s not found in SignalBus" % signal_name)


func manual_scale(new_scale: float) -> void:
	var use: Vector2 = Vector2(new_scale, new_scale)
	scale = use * Vector2(0.4, 0.4)


func scale_HUD_button(new_scale: float) -> void: # Scales entire Control node, not used
	scale = Vector2(new_scale, new_scale)


func return_current_player(track:String) -> AnimationPlayer:
	for anim:AnimationPlayer in animation_players:
			if anim.has_animation(track):
				return anim
	push_error("anim node not found")
	return null


func _handle_dock_animation(state:String) -> void:
	var anim = return_current_player("pulse_BottomRight")
	if state == "on":
		anim.play("pulse_BottomRight")
	elif state == "off":
		anim.stop()
		anim.play("RESET")


func _handle_hail_animation(state:String) -> void:
	var anim = return_current_player("pulse_BottomLeft")
	if state == "on":
		anim.play("pulse_BottomLeft")
	elif state == "off":
		anim.stop()
		anim.play("RESET")


func _handle_beam_animation(state:String) -> void:
	var anim = return_current_player("pulse_TopRight")
	if state == "on":
		anim.play("pulse_TopRight")
	elif state == "off":
		anim.stop()
		anim.play("RESET")


func _handle_debug_inputs(event):
	if event.is_action_pressed("move_forward"):
		var anim = return_current_player("pulse_TopLeft")
		anim.stop()
		anim.play("RESET")
		anim.play("pulse_TopLeft")
	elif event.is_action_pressed("move_backward"):
		var anim = return_current_player("pulse_BottomLeft")
		anim.stop()
		anim.play("RESET")
		anim.play("pulse_BottomLeft")
	elif event.is_action_pressed("rotate_right"):
		var anim = return_current_player("pulse_TopRight")
		anim.stop()
		anim.play("RESET")
		anim.play("pulse_TopRight")
	elif event.is_action_pressed("rotate_left"):
		var anim = return_current_player("pulse_BottomRight")
		anim.stop()
		anim.play("RESET")
		anim.play("pulse_BottomRight")
	elif event.is_action_pressed("letter_q"):
		var anim = return_current_player("pulse_Center")
		anim.stop()
		anim.play("RESET")
		anim.play("pulse_Center")
