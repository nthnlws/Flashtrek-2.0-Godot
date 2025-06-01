extends Resource
class_name ShipResource

var sprite_texture: Texture = preload("res://assets/textures/ships/ship_sprites.png")

# SHIP INFO
@export_category("Ship Info")
@export var name: String
@export var ship_faction: Utility.FACTION
@export var sprite_region: Vector2
@export var collision_polygon: PackedVector2Array

# VISUAL
@export_category("Sprite")
@export var sprite_scale: float = 1.0
@export var shield_scale: Vector2 = Vector2.ONE

# STATS
@export_category("Ship Stats")
@export var default_speed: int = 60
@export var rotation_rate: float = 3
@export var has_shield: bool = true
@export var muzzle_pos: Vector2 = Vector2.ZERO

@export var max_hp:int = 100
@export var max_shield_health:int = 50
