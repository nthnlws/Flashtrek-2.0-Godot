class_name Asteroid extends Area2D

signal exploded(pos, size, points)
signal player_collision(Area: Area2D)

var movement_vector := Vector2(0, -1)
 
enum AsteroidSize{LARGE, MEDIUM, SMALL}
@export var size := AsteroidSize.LARGE

var speed:float= 200

@onready var sprite = $Sprite2D
@onready var cshape = $CollisionPolygon2D

func _init():
	monitoring = true
	monitorable = true
	
	
var points: int:
	get:
		match size:
			AsteroidSize.LARGE:
				return 100
			AsteroidSize.MEDIUM:
				return 50
			AsteroidSize.SMALL:
				return 25
			_:
				return 0

func _ready():
	add_to_group("enemies")
	
	match size:
		AsteroidSize.LARGE:
			speed = randf_range(50, 100)
			sprite.texture = preload("res://assets/textures/meteorGrey_big4.png")
			cshape.set_deferred("shape", preload("res://resources/asteroid_cshape_large.tres"))
		AsteroidSize.MEDIUM:
			speed = randf_range(100, 150)
			sprite.texture = preload("res://assets/textures/meteorGrey_med2.png")
			cshape.set_deferred("shape", preload("res://resources/asteroid_cshape_medium.tres"))
		AsteroidSize.SMALL:
			speed = randf_range(100, 200)
			sprite.texture = preload("res://assets/textures/meteorGrey_tiny1.png")
			cshape.set_deferred("shape", preload("res://resources/asteroid_cshape_small.tres"))

func _physics_process(delta):
	pass

func explode():
	emit_signal("exploded", global_position, size, points)
	queue_free()
