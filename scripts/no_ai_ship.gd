extends Node2D

enum EnemyType {BIRD_OF_PREY, ENTERPRISETOS}

@export var default_speed:int = 50
@export var torpedo: PackedScene

@onready var shield = $enemyShield

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
	var ship_type = randi_range(0, 1)
	shield.processing_active = false
	match ship_type:
		0:
			$Sprite2D.texture = preload("res://assets/textures/ships/birdofprey.png")
			$Sprite2D.scale = Vector2(0.6, 0.6)
			self.scale = Vector2(0.3, 0.3)
			shield.current_enemy_type = ship_type
			shield.scale_shield()
		1:
			$Sprite2D.texture = preload("res://assets/textures/ships/enterpriseTOS.png")
			self.scale = Vector2(0.33, 0.33)
			shield.current_enemy_type = ship_type
			shield.scale_shield()

func choose_shield():
	# 2/3 chance to have shield on
	var shield_chance = randi_range(0, 2)
	match shield_chance:
		0: #Shield off
			shield.queue_free()
		_:
			pass
