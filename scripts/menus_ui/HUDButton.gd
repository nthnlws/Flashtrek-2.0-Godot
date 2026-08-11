extends Control

@onready var texture_button_array: Array[Node] = get_tree().get_nodes_in_group("texture_buttons")
@onready var animation_players: Array[Node] = get_tree().get_nodes_in_group("anims")

@onready var ship_button: TextButton = $MarginContainer/GridContainer/SHIPpanel/ShipButton
@onready var nav_button: TextButton = $MarginContainer/GridContainer/NAVpanel/NavButton
@onready var intel_button: TextButton = $MarginContainer/GridContainer/INTELpanel/IntelButton
@onready var comms_button: TextButton = $MarginContainer/GridContainer/COMMSpanel/CommsButton

func _input(event: InputEvent) -> void:
	if get_tree().get_current_scene().name == "HUD_button" and event is InputEventKey:
		_handle_debug_inputs(event)


func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	SignalBus.HUDchanged.connect(change_scale)
	
	ship_button.button_pressed.connect(_handle_HUD_button_pressed.bind(ship_button))
	nav_button.button_pressed.connect(_handle_HUD_button_pressed.bind(nav_button))
	intel_button.button_pressed.connect(_handle_HUD_button_pressed.bind(intel_button))
	comms_button.button_pressed.connect(_handle_HUD_button_pressed.bind(comms_button))


func _handle_HUD_button_pressed(clicked_button: TextButton) -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		AudioManager.play_UI_click_sound()
		var signal_name: String = clicked_button.name + "_clicked"
		if SignalBus.has_signal(signal_name):
			SignalBus.emit_signal(signal_name)
			# Following signals emitted:
			# ShipButton, NavButton, IntelButton, CommsButton
			#print(str(signal_name) + " emitted")
		else: print("%s not found in SignalBus" % signal_name)


func change_scale(new_scale: float) -> void:
	var use: Vector2 = Vector2(new_scale, new_scale)
	scale = use


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
