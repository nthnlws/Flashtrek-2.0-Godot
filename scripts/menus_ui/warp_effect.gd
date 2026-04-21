@tool
extends ColorRect

@onready var animation: AnimationPlayer = $AnimationPlayer
const anim_length:float = 1.5

# --- Particle Shape and Count ---
@export_group("Particle Count")
@export_range(1, 1000) var star_count: int = 200:
	set(value):
		star_count = value
		_update_shader("star_count", value)
@export_range(1, 500) var arms: int = 100:
	set(value):
		arms = value
		_update_shader("arms", value)
@export_range(0.1, 5.0, 0.1) var particle_size: float = 1.5:
	set(value):
		particle_size = value
		_update_shader("particle_size", value)

# --- Color Gradient ---
@export_group("Color")
@export var use_white_color: bool = false:
	set(value):
		use_white_color = value
		_update_shader("use_white_color", value)
@export var color_a: Color = Color(1.0, 1.0, 1.0, 0.0):
	set(value):
		color_a = value
		_update_shader("color_a", value)
@export var color_b: Color = Color.SKY_BLUE:
	set(value):
		color_b = value
		_update_shader("color_b", value)
@export_range(0.1, 10.0, 0.1) var gradient_speed: float = 5.3:
	set(value):
		gradient_speed = value
		_update_shader("gradient_speed", value)

# --- Animation Physics ---
@export_group("Animation")
@export_range(0, 800, 1.0) var world_scale: float = 400.0:
	set(value):
		world_scale = value
		_update_shader("world_scale", value)
@export_range(50.0, 150.0, 1.0) var theta: float = 80.0:
	set(value):
		theta = value
		_update_shader("theta", value)
@export_range(0.0, 200, 1.0) var centerArea: float = 85.0:
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
@export_range(-50, 50, 0.1) var speed: float = 20.0:
	set(value):
		speed = value
		_update_shader("speed", value)
@export_range(1, 50, 0.1) var modTime: float = 20.0:
	set(value):
		modTime = value
		_update_shader("modTime", value)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"):
		$AnimationPlayer.play("activate_warp")
	elif event.is_action_pressed("debug2"):
		$AnimationPlayer.play("exit_warp")

func _ready() -> void:
	# Force an initial sync of all variables
	_update_shader("star_count", star_count)
	_update_shader("arms", arms)
	_update_shader("particle_size", particle_size)
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
	
	# Keep the shader updated when the ColorRect is resized
	resized.connect(_on_resized)
	_on_resized()

func _on_resized() -> void:
	_update_shader("rect_size", size)

# Helper function to safely send variables to the GPU
func _update_shader(param_name: String, value: Variant) -> void:
	if material and material is ShaderMaterial:
		material.set_shader_parameter(param_name, value)

func exit_warp_animation() -> void:
	animation.play("exit_warp")
func start_warp_animation() -> void:
	animation.play("activate_warp")
