extends CharacterBody2D

@export var default_speed:int = 50
@export var torpedo: PackedScene

var speed:int = default_speed
var shield_on:bool
var is_chaser:bool = false

var shoot_cd:float = false
var rate_of_fire:float = 1.0


func _ready() -> void:
	choose_sprite()
	choose_shield()
			

func choose_sprite():
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

func choose_shield():
	# 2/3 chance to have shield on
	var shield = randi_range(0, 2)
	match shield:
		0: #Shield off
			$enemyShield.queue_free()
		_:
			pass
