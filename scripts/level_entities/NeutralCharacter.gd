extends CharacterBody2D
class_name NeutralCharacter

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionPolygon2D = $hitbox_area/CollisionPolygon2D
@onready var collision_shape: CollisionPolygon2D = $WorldCollisionShape
@onready var shield: Shield = $Shield
@onready var animation: AnimatedSprite2D = $hull_explosion
@onready var sprite_animation: AnimationPlayer = $Sprite2D/SpriteAnimation
@onready var health_component: HealthComponent = $HealthComponent
@onready var movement: ShipMovementComponent = $MovementComponent

var ship_stats: ShipState

const AIState = ShipMovementComponent.State
const DISTRESS_COOLDOWN_MSEC: int = 3000

var ship_index: int # Used for tying ship to Data resource files
var cloaked: bool = false

var _last_distress_msec: int = -DISTRESS_COOLDOWN_MSEC


func _ready() -> void:
	_create_unique_texture_atlas()
	sync_ship_to_resource()
	z_index = Utility.Z["NeutralShips"]
	movement.think_tick.connect(_think)


func _create_unique_texture_atlas() -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.filter_clip = true
	sprite.texture = atlas_texture


func sync_ship_to_resource() -> void:
	var ship_info: BaseShipInfo = Utility.get_ship_stats(ship_stats.ship_type)
	sprite.texture.region = Rect2(ship_info.sprite_coords, Vector2(48, 48))
	shield.scale = ship_info.shield_scale

	health_component.setMaxHealth(ship_stats.scaled_max_HP)
	health_component.setCurrentHealth(ship_stats.scaled_max_HP)
	health_component.setMaxShield(ship_stats.scaled_max_shield)
	health_component.setCurrentShield(ship_stats.scaled_max_shield)

	var rawColl = ship_info.collision_polygon
	var parsed_array = JSON.parse_string(rawColl)
	var PV2Array = PackedVector2Array()
	for pair in parsed_array:
		PV2Array.append(Vector2(pair[0], pair[1]))
	PV2Array = center_polygon(PV2Array)
	collision_shape.polygon = PV2Array
	hitbox.polygon = PV2Array


func center_polygon(points: Array) -> PackedVector2Array:
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y

	# Find bounds
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var center_x = (min_x + max_x) / 2.0
	var center_y = (min_y + max_y) / 2.0

	var adjusted_points:Array = []
	for p in points:
		var centered:Vector2 = Vector2(p.x - center_x, p.y - center_y)
		var shifted:Vector2 = centered + Vector2(1, -4)
		adjusted_points.append(shifted)

	return PackedVector2Array(adjusted_points)


func _set_ship_scale(new_scale: Vector2) -> void:
	shield.scale *= new_scale
	sprite.scale *= new_scale
	$hitbox_area.scale *= new_scale


## Decision hook, called every ShipMovementComponent.THINK_INTERVAL.
func _think() -> void:
	pass


# --- Helpers ---

func get_hull_fraction() -> float:
	return health_component.getCurrentHP() / maxf(health_component.getMaxHealth(), 1.0)


static func faction_of(body: Node) -> Utility.FACTION:
	if is_instance_valid(body) and "ship_stats" in body and body.ship_stats:
		return body.ship_stats.current_faction
	return Utility.FACTION.NEUTRAL


func _emit_distress(attacker: Node2D) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_distress_msec < DISTRESS_COOLDOWN_MSEC or not is_instance_valid(attacker):
		return
	_last_distress_msec = now
	SignalBus.ship_distress.emit(self, attacker)


# --- Combat callbacks ---

func _on_hit_received(shooter: Node) -> void:
	var attacker: Node2D = shooter as Node2D
	if not is_instance_valid(attacker):
		return
	_emit_distress(attacker)
	movement.flee_from(attacker.global_position)


func explode(hit_event:HitEvent = HitEvent.new()) -> void:
	shield.turnShieldOff()
	sprite.visible = false

	SignalBus.neutralShipDied.emit(self)
	if hit_event.is_from_player: # Update reputation if died from player damage
		SignalBus.reputation_change_triggered.emit(ship_stats.current_faction, ship_stats.reputation_value)

	collision_shape.set_deferred("disabled", true)
	hitbox.set_deferred("disabled", true)
	%ship_explosion.play()

	animation.visible = true
	animation.play("explode")
	await animation.animation_finished

	queue_free()


func trigger_warp_effect(length:float, warp_effect_on: bool) -> void:
	sprite_animation.speed_scale = 2/length

	if warp_effect_on:
		cloaked = true
		sprite_animation.play("galaxy_warp_out")
	else:
		sprite_animation.play("galaxy_warp_in")
		await sprite_animation.animation_finished
		cloaked = false
