extends ColorRect

@export var max_SP: float = 100.0
var current_SP: float = 100.0:
	set(value):
		current_SP = clampf(value, 0.0, max_SP)
		var ratio = 0.0
		if max_SP > 0.0:
			ratio = current_SP / max_SP
		(material as ShaderMaterial).set_shader_parameter("health_ratio", ratio)

func _ready() -> void:
	SignalBus.playerShieldOff.connect(handle_player_shield_state.bind("OFF"))
	SignalBus.playerShieldOn.connect(handle_player_shield_state.bind("ON"))
	current_SP = max_SP

func handle_player_shield_state(state:String) -> void:
	var mat: ShaderMaterial = material
	match state:
		"ON":
			mat.set_shader_parameter("color", Color("5c86d5"))
		"OFF":
			mat.set_shader_parameter("color", Color("d65865"))

# Debug func for shader testing
#func _input(event): 
	#if Input.is_action_just_pressed("move_backward"):
		#self.current_SP -= 10
		#print("Shield Health: ", current_SP)
	#if Input.is_action_just_pressed("move_forward"):
		#self.current_SP += 10
		#print("Shield Health: ", current_SP)
