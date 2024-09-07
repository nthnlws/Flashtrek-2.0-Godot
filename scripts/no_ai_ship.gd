extends CharacterBody2D

@export var default_speed:int = 50
@export var torpedo: PackedScene

var speed:int = default_speed
var shield_on:bool

var shoot_cd:float = false
var rate_of_fire:float = 1.0


func _ready() -> void:
	# 1/2 chance for either ship sprite
	var sprite = randi_range(0, 1)
	match sprite:
		0: #Shield on
			$Sprite2D.texture = preload("res://assets/textures/ships/enterpriseTOS.png")
			$Sprite2D.scale = Vector2(1.2, 1.2)
			self.scale = Vector2(0.3, 0.3)
		1: #Shield on
			$Sprite2D.texture = preload("res://assets/textures/ships/birdofprey.png")
			self.scale = Vector2(0.3, 0.3)
			
			
	# 2/3 chance to have shield on
	var shield = randi_range(0, 2)
	match shield:
		0: #Shield on
			pass
		1: #Shield on
			pass
		2: #Shield off
			$enemyShield.queue_free()
