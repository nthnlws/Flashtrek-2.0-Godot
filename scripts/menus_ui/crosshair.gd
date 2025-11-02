extends Node2D

@onready var energy_bar: TextureProgressBar = $ProgressBar

func  _ready() -> void:
	if visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	SignalBus.playerEnergyChanged.connect(update_energy_value)
	SignalBus.playerMaxEnergyChanged.connect(update_energy_max)


func _process(delta: float) -> void:
	position = get_global_mouse_position()


func update_energy_max(new_value:float) -> void:
	energy_bar.max_value = new_value
func update_energy_value(new_value:float) -> void:
	energy_bar.value = new_value


func _on_visibility_changed() -> void:
	if visible == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
