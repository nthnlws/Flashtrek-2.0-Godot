extends Camera2D

# constants for screenshake
const DECAY = 0.85
const MAX_ROT = 0.1
const MAX_OFF = Vector2(100, 100)

var trauma: float = 0.0
var trauma_power: int = 1
var noise_y: int = 0

onready var noise = OpenSimplexNoise.new()


func _ready() -> void:
	randomize()
	noise.seed = randi()
	noise.period = 3
	noise.octaves = 3

	EventBus.connect("player_hit", self, "_on_player_hit")


func _process(delta: float) -> void:
	trauma = max(trauma - DECAY * delta, 0)
	shake_camera()


# function add trauma to the camera causing a shake
func add_trauma(value: float = 0.0) -> void:
	trauma = min(trauma + value, 0.35)
	# vibrated the controlled using the trauma & value
	# to give some contrast between the strong and weak magnitude.
	Input.start_joy_vibration(0, value, trauma, 0.5)


# function that will change the rotation and offset of the camera for the shake
func shake_camera() -> void:
	var ammount = pow(trauma, trauma_power)
	noise_y += 1
	rotation = MAX_ROT * ammount * noise.get_noise_2d(noise.seed, noise_y)
	rotation = MAX_ROT * ammount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = MAX_OFF.x * ammount * noise.get_noise_2d(noise.seed * 2, noise_y)
	offset.y = MAX_OFF.y * ammount * noise.get_noise_2d(noise.seed * 3, noise_y)


func _on_player_hit() -> void:
	add_trauma(0.2)
