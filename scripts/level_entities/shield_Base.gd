extends Node2D
class_name Shield

@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var shield_area:Area2D = $shield_area
@onready var sprite: ColorRect = $ColorRect
@onready var is_on_player:bool = get_parent() is Player

@export var health_component: HealthComponent

var shieldActive: bool = true:
	set(value):
		shieldActive = value
		if is_on_player:
			if shieldActive: SignalBus.playerShieldOn.emit()
			else: SignalBus.playerShieldOff.emit()

var fade_length: float = 0.8


func _on_damage_received(hit_event:HitEvent):
	health_component.collect_damage_events(hit_event)


# Fades shield to 0 Alpha
func fadeout_INSTANT() -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(sprite, "modulate:a", 0, fade_length)
	await tween.finished
	collision_shape.set_deferred("disabled", true)
	shieldActive = false


func fadeout_SMOOTH() -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(sprite, "modulate:a", 0, fade_length)
	await tween.finished
	collision_shape.set_deferred("disabled", true)
	shieldActive = false


# Fades shield in to 255 Alpha
func fadein_INSTANT() -> void:
	sprite.modulate.a = 1  # Instantly set alpha to 1 (255 equivalent)
	collision_shape.set_deferred("disabled", false)
	shieldActive = true


func fadein_SMOOTH() -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(sprite, "modulate:a", 1, fade_length)
	await tween.finished
	collision_shape.set_deferred("disabled", false)
	shieldActive = true


func turnShieldOff() -> void: #Instantly turns off shield
	collision_shape.set_deferred("disabled", true)
	self.visible = false
	shieldActive = false
	await get_tree().create_timer(3).timeout
	turnShieldOn()


func turnShieldOn() -> void: #Instant on shield
	collision_shape.set_deferred("disabled", false)
	self.visible = true
	shieldActive = true
