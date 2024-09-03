extends ParallaxLayer

# Variables for controlling spawn rate and range
@export var spawn_interval:float = 6.0  # Time between spawns
@export var initial_planet_count = 10

# Timer for spawning new sprites
var spawn_timer = spawn_interval - 0.1

func _ready():
	for i in range(initial_planet_count):
		spawn_tumbling_sprite(true)
	
	# Start normal spawning
	spawn_timer = spawn_interval
	set_process(true)

func _process(delta):
	# Update the spawn timer
	spawn_timer -= delta
	if spawn_timer <= 0:
	# Spawn a new sprite when the timer reaches 0
		spawn_tumbling_sprite(false)
		# Reset the spawn timer
		spawn_timer = spawn_interval

func spawn_tumbling_sprite(is_initial: bool):
	# Create a new sprite
	var sprite = Sprite2D.new()
	var sprite_script = preload("res://scripts/rotating_planets.gd")
	
	
	# Randomly select the texture
	var random_index = "%03d" % randi_range(1, 221)
	var sprite_path = "res://assets/textures/planets/planet_%s.png" % random_index
	sprite.texture = load(sprite_path)

	# Randomly set the rotation
	sprite.rotation = deg_to_rad(randi_range(0, 360))

	# Randomly set the scale
	var scale_modifier = randf_range(0.15, 0.3)
	sprite.scale = Vector2(scale_modifier, scale_modifier)

	if is_initial:
		# Position planets randomly on the screen for the initial spawn
		sprite.position = Vector2(randi_range(0, int(get_viewport_rect().size.x)), randi_range(0, int(get_viewport_rect().size.y)))
	else:
		# Position planets off-screen to the right for regular spawning
		sprite.position = Vector2(get_viewport_rect().size.x + (sprite.texture.get_width()*sprite.scale.x),
							randi_range(0, int(get_viewport_rect().size.y)))
	

	add_child(sprite)
	sprite.set_script(sprite_script)

	# Set the movement speed


	# Animate the sprite across the screen with tumbling
	sprite.set_process(true)
	
