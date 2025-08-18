class_name baseShield extends Node2D

@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var shield_area:Area2D = $shield_area
@onready var sprite: ColorRect = $ColorRect

signal shieldStatusChanged(status:bool)

var damageTime:bool = false # Timeout
var shieldActive:bool = true:
	set(value):
		if shieldActive == value: return
		shieldStatusChanged.emit(value)
		shieldActive = _set_shield_active(value)

var trans_length:float = 0.8
@export var regen_speed:float = 2.5

# Shield health variables
@export var sp_max:int = 50:
	set(value):
		sp_max = set_shield_max(value)
var sp_current:float = sp_max:
	set(value): 
		if sp_current == value: return
		sp_current = set_shield_value(value)


func _ready() -> void:
	modulate.a = 1.0

func _set_shield_active(state:bool):
	return state


func set_shield_value(value) -> float:
	return clamp(value, 0.0, sp_max)


func set_shield_max(value) -> float:
	return value


func regen_shield(delta: float) -> void:
	sp_current += regen_speed * delta


# Fades shield to 0 Alpha
func fadeout_INSTANT() -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(sprite, "modulate:a", 0, trans_length)
	await tween.finished
	collision_shape.set_deferred("disabled", true)
	shieldActive = false


func fadeout_SMOOTH() -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(sprite, "modulate:a", 0, trans_length)
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
	tween.tween_property(sprite, "modulate:a", 1, trans_length)
	await tween.finished
	collision_shape.set_deferred("disabled", false)
	shieldActive = true


func turnShieldOff() -> void: #Instantly turns off shield
	collision_shape.set_deferred("disabled", true)
	self.visible = false
	shieldActive = false
	sp_current = 0.1
	await get_tree().create_timer(3).timeout
	turnShieldOn()


func turnShieldOn() -> void: #Instant on shield
	collision_shape.set_deferred("disabled", false)
	self.visible = true
	shieldActive = true

 
func damageTimeout() -> void: #Turns off shield regen for 1 second after damage taken
	damageTime = true
	if $Timer.is_stopped() == false: # If timer is already running, restarts timer fresh
		$Timer.stop()
		$Timer.start()
		await $Timer.timeout
		damageTime = false
	if $Timer.is_stopped() == true: # Starts timer if it is not already
		$Timer.start()
		await $Timer.timeout
		damageTime = false
