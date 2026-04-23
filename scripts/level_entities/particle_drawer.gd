@tool
extends ColorRect

# --- Particle Shape and Count ---
@export_group("Particle Count")
@export_range(1, 1000) var star_count: int = 200:
	set(value):
		star_count = value
		_update_counts()

@export_range(1, 500) var arms: int = 100:
	set(value):
		arms = value
		_update_counts()

# --- Color Gradient ---
@export_group("Color")
@export var use_white_color: bool = false:
	set(value):
		use_white_color = value
		_update_shader("use_white_color", value)
@export var color_a: Color = Color.WHITE:
	set(value):
		color_a = value
		_update_shader("color_a", value)
@export var color_b: Color = Color.SKY_BLUE:
	set(value):
		color_b = value
		_update_shader("color_b", value)
@export_range(0.1, 10.0, 0.1) var gradient_speed: float = 3.3:
	set(value):
		gradient_speed = value
		_update_shader("gradient_speed", value)

# --- Animation Physics ---
@export_group("Animation")
@export var world_scale: float = 300.0:
	set(value):
		world_scale = value
		_update_shader("world_scale", value)
@export var haszExpend: bool = false # Kept for inspector compatibility
@export_range(50.0, 150.0, 1.0) var theta: float = 80.0:
	set(value):
		theta = value
		_update_shader("theta", value)
@export_range(0.0, 200, 1.0) var centerArea: float = 15.0:
	set(value):
		centerArea = value
		_update_shader("centerArea", value)
@export_range(0.01, 0.05, 0.001) var scale_x: float = 0.01:
	set(value):
		scale_x = value
		_update_shader("scale_x", value)
@export_range(0, 10, 0.01) var stretch: float = 1.4:
	set(value):
		stretch = value
		_update_shader("stretch", value)
@export_range(-50, 50, 0.1) var speed: float = 15.5:
	set(value):
		speed = value
		_update_shader("speed", value)
@export_range(1, 50, 0.1) var modTime: float = 20.0:
	set(value):
		modTime = value
		_update_shader("modTime", value)


func _ready() -> void:
	_update_counts()

	# Force sync all initial variables to the shader
	_update_shader("use_white_color", use_white_color)
	_update_shader("color_a", color_a)
	_update_shader("color_b", color_b)
	_update_shader("gradient_speed", gradient_speed)
	_update_shader("world_scale", world_scale)
	_update_shader("theta", theta)
	_update_shader("centerArea", centerArea)
	_update_shader("scale_x", scale_x)
	_update_shader("stretch", stretch)
	_update_shader("speed", speed)
	_update_shader("modTime", modTime)


func _update_counts() -> void:
	_update_shader("star_count", star_count)
	_update_shader("arms", arms)


# Helper function to safely send variables to the GPU
func _update_shader(param_name: String, value: Variant) -> void:
	if material and material is ShaderMaterial:
		material.set_shader_parameter(param_name, value)
