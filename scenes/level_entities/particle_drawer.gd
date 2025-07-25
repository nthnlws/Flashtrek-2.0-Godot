extends MultiMeshInstance2D

# --- Particle Shape and Count ---
@export_group("Particle Count")
@export_range(1, 1000) var star_count: int = 200:
	set(value):
		set_instance_count(value, arms)
@export_range(1, 500) var arms: int = 100:
	set(value):
		set_instance_count(star_count, value)
		
# --- Color Gradient ---
@export_group("Color")
@export var use_white_color: bool = false
@export var color_a: Color = Color.WHITE
@export var color_b: Color = Color.SKY_BLUE
@export_range(0.1, 10.0, 0.1) var gradient_speed: float = 3.3

# --- Animation Physics ---
@export_group("Animation")
@export var world_scale: float = 300.0
@export var haszExpend: bool = false
@export_range(50.0, 150.0, 1.0) var theta: float = 80.0
@export_range(0.0, 200, 1.0) var centerArea: float = 15.0
@export_range(0.01, 0.05, 0.001) var scale_x: float = 0.01
@export_range(0, 10, 0.01) var stretch: float = 1.4
@export_range(-50, 50, 0.1) var speed: float = 15.5
@export_range(1, 50, 0.1) var modTime: float = 20.0

func _ready():
	if multimesh:
		multimesh.instance_count = 0
		multimesh.use_colors = true
	set_instance_count(star_count, arms)

func set_instance_count(star:int, arm:int):
	if multimesh:
		multimesh.instance_count = star * arm

func _process(delta):
	if not multimesh:
		return

	var instance_count = multimesh.instance_count
	if instance_count != star_count * arms:
		multimesh.instance_count = star_count * arms

	var time = Time.get_ticks_msec() / 1000.0
	var tan_theta = tan(deg_to_rad(theta))
	var scale_stretch = scale_x * stretch
	var time_offset = 13.0 + time * speed
	var z_expend_factor = scale_x * modTime * 0.5

	var instance_index = 0
	for j in range(1, arms + 1):
		var seed_input = Vector2(2.0 - j, float(j) * 37.0)
		var current_seed = fposmod(sin(seed_input.dot(Vector2(12.9898, 78.233))) * 46751.5453, 1.0)
		
		var alpha = current_seed * TAU
		var dir = Vector2(cos(alpha), sin(alpha))
		var progress_j_base = time_offset + float(arms) / float(j) * 10.0

		for i in range(star_count):
			# --- Position Calculation ---
			var base_progress_value = progress_j_base + float(i) * scale_stretch
			var z_mod_cycle = fmod(base_progress_value, modTime)
			var z = z_mod_cycle * scale_x

			var H = centerArea * scale_x + z * tan_theta
			var nuv = H * dir
			
			var particle_transform = Transform2D()
			particle_transform.origin = nuv * world_scale
			particle_transform = particle_transform.scaled(Vector2.ONE)
			
			# --- Color Calculation Logic ---
			var final_color: Color
			if use_white_color:
				final_color = Color.WHITE
			else:
				# Normalized progress of the particle within its current cycle (0.0 to 1.0)
				var normalized_progress = z_mod_cycle / modTime
				# Mix factor from 0 (color_a) to 1 (color_b)
				var mix_factor = clampf(normalized_progress * gradient_speed, 0.0, 1.0)
				# In GDScript, mix() is called lerp()
				final_color = color_a.lerp(color_b, mix_factor)

			# --- Apply Transform and Color to the particle ---
			multimesh.set_instance_transform_2d(instance_index, particle_transform)
			multimesh.set_instance_color(instance_index, final_color) # Apply the calculated color
			
			instance_index += 1
