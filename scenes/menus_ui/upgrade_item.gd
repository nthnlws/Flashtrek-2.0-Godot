class_name UpgradePickup
extends Area2D

enum MODULE_TYPES { SPEED, ROTATION, FIRE_RATE, HEALTH, SHIELD, DAMAGE }
enum MODIFIER { ADD, MULT }

@export var modifier_type: MODIFIER = MODIFIER.MULT
@export var upgrade_type: MODULE_TYPES = MODULE_TYPES.SPEED:
	set(value):
		upgrade_type = value
		if is_node_ready():
			change_icon_sprite(value)

const FIRE_RATE_UPGRADE_ICON = preload("res://assets/textures/UI/fire_rate_upgrade_icon.png")
const ROTATION_UPGRADE_ICON = preload("res://assets/textures/UI/rotation_upgrade_icon.png")
const SPEED_UPGRADE_ICON = preload("res://assets/textures/UI/speed_upgrade_icon.png")
const HEALTH_UPGRADE_ICON = preload("res://assets/textures/UI/health_upgrade_icon.png")
const SHIELD_UPGRADE_ICON = preload("res://assets/textures/UI/shield_upgrade_icon.png")
const DAMAGE_UPGRADE_ICON = preload("res://assets/textures/UI/damage_upgrade_icon.png")

@onready var sprite: Sprite2D = $UpgradeIcon


func _ready() -> void:
	self.add_to_group("upgrade_drop")
	
	body_entered.connect(_on_player_entered)
	change_icon_sprite(upgrade_type)
	
	z_index = Utility.Z["LootDrops"]
	
	
func _on_player_entered(body: Node2D) -> void:
	if body.has_method("apply_upgrade"):
		body.apply_upgrade(self)
		queue_free()


func change_icon_sprite(type: MODULE_TYPES) -> void:
	match type:
		MODULE_TYPES.SPEED:
			sprite.texture = SPEED_UPGRADE_ICON
		MODULE_TYPES.ROTATION:
			sprite.texture = ROTATION_UPGRADE_ICON
		MODULE_TYPES.FIRE_RATE:
			sprite.texture = FIRE_RATE_UPGRADE_ICON
		MODULE_TYPES.HEALTH:
			sprite.texture = HEALTH_UPGRADE_ICON
		MODULE_TYPES.SHIELD:
			sprite.texture = SHIELD_UPGRADE_ICON
		MODULE_TYPES.DAMAGE:
			sprite.texture = DAMAGE_UPGRADE_ICON
