extends Resource
class_name Vessel

enum CLASS_SIZE { SMALL, MEDIUM, LARGE }


@export var enemy_type: Utility.SHIP_TYPES

@export var class_size: CLASS_SIZE
@export var class_faction: Utility.FACTION = 0


var sprite_scale: Vector2:
	get: 
		match class_size:
			CLASS_SIZE.SMALL:
				return Vector2(2.5, 2.5)
			CLASS_SIZE.MEDIUM:
				return Vector2(4, 4)
			CLASS_SIZE.LARGE:
				return Vector2(5, 5)
		return Vector2(1, 1)

var shield_multipler:Vector2 = Vector2(5, 5) # Default shield size for normal (medium) craft

var class_shield_scale:Vector2 = Vector2(1, 1): # Default scaling 
	get:
		match class_size:
			CLASS_SIZE.SMALL:
				return shield_multipler * Vector2(2.5, 2.5)
			CLASS_SIZE.MEDIUM:
				return shield_multipler * Vector2(4, 4)
			CLASS_SIZE.LARGE:
				return shield_multipler * Vector2(6, 6)
		return shield_multipler

@export var ship_shield_scale: Vector2 = Vector2(1, 1)

var collision_scale:float

@export var default_speed: int = 60
@export var rotation_rate: float = 3
@export var has_shield: bool = true
@export var muzzle_pos: Vector2 = Vector2(0, -12)
@export var RANDOMNESS_ANGLE_DEGREES: float = 3.0
@export var detection_radius: int = 1200

@export var max_hp:int = 100
@export var max_shield_health:int = 50
@export var max_cargo_size:int = 1
@export var max_antimatter:int = 1

@export var sprite_texture: Texture = preload("res://assets/textures/ships/ship_sprites.png")

@export var weapon: PackedScene = preload("res://scenes/torpedo.tscn")
@export var collision_shape: ConvexPolygonShape2D
