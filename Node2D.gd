extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var _health = 100

	# Setter method for the 'health' property
func set_health(value):
	if value < 0:
		_health = 0
	elif value > 100:
		_health = 100
	else:
		_health = value

	# Getter method for the 'health' property
func get_health():
	return _health

# Usage
var player = Player.new()
player.health = 80  # This automatically calls the set_health method
print(player.health)  # This automatically calls the get_health method
