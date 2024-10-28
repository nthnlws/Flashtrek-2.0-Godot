extends Resource
class_name Enemy

@export var enemy_type: String
@export var current_enemy_type: int
@export var sprite_scale:float
@export var default_speed: int
@export var rotation_rate: float
@export var shield_on: bool
@export var rate_of_fire: float
@export var RANDOMNESS_ANGLE_DEGREES: float
@export var detection_radius: int

@export var max_hp:int
@export var max_shield_health:int

@export var sprite_texture: Texture
@export var torpedo: PackedScene
@export var collision_shape: Shape2D
