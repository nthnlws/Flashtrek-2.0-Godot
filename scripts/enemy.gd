extends Resource
class_name Enemy


@export var enemy_type: Utility.ENEMY_TYPE

@export var sprite_scale:float
@export var shield_scale:Vector2
@export var collision_scale:float

@export var default_speed: int
@export var rotation_rate: float
@export var shield_on: bool
@export var rate_of_fire: float
@export var RANDOMNESS_ANGLE_DEGREES: float
@export var detection_radius: int

@export var max_hp:int
@export var max_shield_health:int

@export var sprite_texture: Texture = preload("res://assets/textures/ships/ship_sprites.png")
@export var frame_coords: Vector2

@export var torpedo: PackedScene
@export var collision_shape: ConvexPolygonShape2D
