class_name Enemy extends Area2D

signal exploded(pos, size, points)
signal player_collision(Area: Area2D)

var movement_vector := Vector2(0, -1)
 
var speed:float= 200

@onready var sprite = $Sprite2D
@onready var cshape = $CollisionPolygon2D	

func _physics_process(delta):
	pass

func explode():
	#emit_signal("exploded", global_position, points) # Connects to game.gd _on_asteroid_exploded()
	queue_free()
	print("explodeexplode")
	self.visible = false

func _on_enemy_area_entered(area):
	if area.is_in_group("torpedo"):
		explode()
		area.queue_free()
