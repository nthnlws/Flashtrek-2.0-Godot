extends Sprite2D

@onready var parent = $".."

var pressing = false
var playerDirection: Vector2 = Vector2(0, 0):
	set(value):
		if value != playerDirection:
			playerDirection = value
			SignalBus.joystickMoved.emit(playerDirection)
	
@export var maxLength = 50
var deadzone = 15

func _ready():
	if OS.get_name() == "Android":
		parent.visible = true


func _process(delta):
	if pressing:
		if get_global_mouse_position().distance_to(parent.global_position) <= maxLength:
			global_position = get_global_mouse_position()
		else:
			var angle = parent.global_position.angle_to_point(get_global_mouse_position())
			global_position.x = parent.global_position.x + cos(angle) * maxLength
			global_position.y = parent.global_position.y + sin(angle) * maxLength
		calculateVector()
	else:
		global_position = lerp(global_position, parent.global_position, delta * 50)
		playerDirection = Vector2.ZERO
		
func calculateVector():
	var direction = Vector2(
		global_position.x - parent.global_position.x,
		global_position.y - parent.global_position.y
	)

	if direction.length() >= deadzone:
		# Normalize direction and scale based on maxLength to ensure proper values for both X and Y
		playerDirection = direction / maxLength
	else:
		playerDirection = Vector2.ZERO
	

func _on_button_button_down():
	pressing = true


func _on_button_button_up():
	pressing = false
