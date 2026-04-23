extends Node2D

@onready var energy_bar: TextureProgressBar = $ProgressBar
var player: Player

const valid_aim_color: Color = Color("3a83cf")
const invalid_aim_color: Color = Color("f4bf00")

func  _ready() -> void:
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	SignalBus.playerEnergyChanged.connect(update_energy_value)
	SignalBus.playerMaxEnergyChanged.connect(update_energy_max)
	SignalBus.entering_new_system.connect(func(): visible = true)
	
	call_deferred("set_player")

func set_player() -> void:
	player = LevelManager.player

func _process(delta: float) -> void:
	if Utility.current_menu != Utility.MENUSTATE.NONE: return
	global_position = get_global_mouse_position()
	
	# Check if mouse is over any UI control
	var mouse_over_ui: bool = _is_mouse_over_ui()
	visible = not mouse_over_ui
	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE if mouse_over_ui else Input.MOUSE_MODE_HIDDEN
	)
	
	if !player: return
	var mouse_angle: float = player.global_position.angle_to_point(player.get_global_mouse_position())
	var angle_diff: float = angle_difference(player.rotation, mouse_angle)
	const MAX_AIM_DEVIATION: float = deg_to_rad(35.0)
	
	
	if abs(angle_diff) <= MAX_AIM_DEVIATION:
		#print('valid aim')
		if energy_bar.tint_progress != valid_aim_color:
			#print('switching to valid color')
			energy_bar.tint_progress = valid_aim_color
	elif abs(angle_diff) > MAX_AIM_DEVIATION:
		#print('invalid aim')
		if energy_bar.tint_progress != invalid_aim_color:
			#print('setting to invalid color')
			energy_bar.tint_progress = invalid_aim_color


func update_energy_max(new_value:float) -> void:
	energy_bar.max_value = new_value
func update_energy_value(new_value:float) -> void:
	energy_bar.value = new_value

func _is_mouse_over_ui() -> bool:
	var control_under_mouse: Control = get_viewport().gui_get_hovered_control()
	if control_under_mouse == null:
		return false
	return control_under_mouse.is_in_group("default_mouse")


func _on_visibility_changed() -> void:
	if visible == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
