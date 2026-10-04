## Hitbox for objectives without a HealthComponent. Player and
## protected_faction shots pass through.
class_name ObjectiveDamageReceiver
extends Area2D

signal damaged(amount: float)

const ENEMY_DAMAGE_AREA_LAYER: int = 128

var protected_faction: Utility.FACTION = Utility.FACTION.NEUTRAL


static func create(radius: float, faction: Utility.FACTION) -> ObjectiveDamageReceiver:
	var receiver: ObjectiveDamageReceiver = ObjectiveDamageReceiver.new()
	receiver.protected_faction = faction
	receiver.collision_layer = ENEMY_DAMAGE_AREA_LAYER
	receiver.collision_mask = 0
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	receiver.add_child(collision)
	return receiver


## Queried by Torpedo before detonating.
func blocks_projectile(torpedo: Torpedo) -> bool:
	var from_player: bool = is_instance_valid(torpedo.shooterObject) and torpedo.shooterObject.is_in_group("player")
	return not from_player and torpedo.faction != protected_faction


func can_recieve_damage(hit_event: HitEvent) -> void:
	if hit_event.is_from_player or hit_event.shooter_faction == protected_faction:
		return
	damaged.emit(hit_event.damage_amount)
