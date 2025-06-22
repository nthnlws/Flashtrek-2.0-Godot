class_name Shield extends Sprite2D

@onready var parent: Node = get_parent()
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var shield_area:Area2D = $shield_area


var damageTime:bool = false # Timeout
var shieldActive:bool = true:
	set(value):
		shieldActive = _set_shield_active(value)

var trans_length:float = 0.8
@export var regen_speed:float = 2.5


# Shield health variables
@export var sp_max:int = 50
var sp_current:float = sp_max:
	set(value): 
		sp_current = set_shield(value)

func _set_shield_active(state:bool):
	return state


func set_shield(value) -> float:
	return clamp(value, 0.0, sp_max)


func regen_shield(delta: float) -> void:
	sp_current += regen_speed * delta


# Fades shield to 0 Alpha
func fadeout_INSTANT() -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 0, trans_length)
	await tween.finished
	collision_shape.set_deferred("disabled", true)
	shieldActive = false


func fadeout_SMOOTH() -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 0, trans_length)
	await tween.finished
	collision_shape.set_deferred("disabled", true)
	shieldActive = false


# Fades shield in to 255 Alpha
func fadein_INSTANT() -> void:
	modulate.a = 1  # Instantly set alpha to 1 (255 equivalent)
	collision_shape.set_deferred("disabled", false)
	shieldActive = true


func fadein_SMOOTH() -> void:
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 1, trans_length)
	await tween.finished
	collision_shape.set_deferred("disabled", false)
	shieldActive = true


func shieldDie() -> void: #Instantly turns off shield
	collision_shape.set_deferred("disabled", true)
	self.visible = false
	shieldActive = false
	sp_current = 0.1
	await get_tree().create_timer(3).timeout
	shieldAlive()


func shieldAlive() -> void: #Instant on shield
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
