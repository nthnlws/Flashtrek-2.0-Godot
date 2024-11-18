extends Resource
class_name Enemy

enum CLASS_SIZE { SMALL, MEDIUM, LARGE }

@export var enemy_type: Utility.ENEMY_TYPE
@export var class_size: CLASS_SIZE
@export var class_faction: Utility.FACTION

var sprite_scale: Vector2:
	get: 
		match class_size:
			CLASS_SIZE.SMALL:
				return Vector2(0.5, 0.5)
			CLASS_SIZE.MEDIUM:
				return Vector2(1, 1)
			CLASS_SIZE.LARGE:
				return Vector2(1.5, 1.5)
		return Vector2(1, 1)

var shield_multipler:Vector2 = Vector2(14, 14) # Default shield size for normal (medium) craft

var class_shield_scale:Vector2 = Vector2(1, 1): # Default scaling 
	get:
		match class_size:
			CLASS_SIZE.SMALL:
				return shield_multipler * Vector2(0.5, 0.5)
			CLASS_SIZE.MEDIUM:
				return shield_multipler * Vector2(0.85, 0.85)
			CLASS_SIZE.LARGE:
				return shield_multipler * Vector2(1.25, 1.25)
		return shield_multipler

@export var ship_shield_scale: Vector2 = Vector2(1, 1):
	get:
		return class_shield_scale * ship_shield_scale

var collision_scale:float

@export var default_speed: int = 60
@export var rotation_rate: float = 3
@export var shield_on: bool
@export var rate_of_fire: float
@export var muzzle_pos: Vector2 = Vector2(0, -150)
@export var RANDOMNESS_ANGLE_DEGREES: float
@export var detection_radius: int = 1200

@export var max_hp:int = 100
@export var max_shield_health:int = 50

@export var sprite_texture: Texture = preload("res://assets/textures/ships/ship_sprites.png")
@export var frame_coords: Vector2

@export var torpedo: PackedScene = preload("res://scenes/torpedo.tscn")
@export var collision_shape: ConvexPolygonShape2D
