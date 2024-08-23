extends Sprite2D

const min_speed:float = 10.0
const max_speed:float = 25.0

const max_rotation:float = 2.5
const min_rotation:float = 10.0

var direction: int
var speed = randi_range(min_speed, max_speed)

#func _ready():
	#var rand = randi_range(0, 1)
	#if rand == 0: direction = -1
	#elif rand == 1: direction = 1
	#print(direction)
	#print(rand)
	

func _process(delta):
	position.x -= speed * delta

	rotation += deg_to_rad(speed/3) * -delta

	# Remove the sprite if it goes off-screen
	if position.x < -texture.get_width():
		queue_free()
