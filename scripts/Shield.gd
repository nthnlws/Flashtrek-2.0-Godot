class_name Shield extends Sprite2D

@onready var parent: Node = get_parent()

var damageTime:bool = false # Timeout
var shieldActive:bool = true

var trans_length:float = 0.8
@export var regen_speed:float = 2.5

@onready var shield_area:Area2D = $shield_area

# Enemy shield health variables
@export var sp_max:int = 50
var sp_current:float = sp_max:
	get: return clamp(sp_current, 0, sp_max)
	


func regen_shield(delta):
	sp_current += regen_speed * delta
	
	
# Fades shield to 0 Alpha
func fadeout_INSTANT():
	var tween: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 0, trans_length)
	await tween.finished
	shield_area.set_monitoring.call_deferred(false)
	shield_area.set_monitorable.call_deferred(false)
	shieldActive = false

func fadeout_SMOOTH():
	var tween: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 0, trans_length)
	await tween.finished
	shield_area.set_monitoring.call_deferred(false)
	shield_area.set_monitorable.call_deferred(false)
	shieldActive = false

# Fades shield in to 255 Alpha
func fadein_INSTANT():
	modulate.a = 1  # Instantly set alpha to 1 (255 equivalent)
	shield_area.set_monitoring(true)
	shield_area.set_monitorable(true)
	shieldActive = true

func fadein_SMOOTH():
	var tween: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 1, trans_length)
	await tween.finished
	shield_area.set_monitoring.call_deferred(true)
	shield_area.set_monitorable.call_deferred(true)
	shieldActive = true

func shieldDie(): #Instantly turns off shield
	shield_area.set_monitoring.call_deferred(false)
	shield_area.set_monitorable.call_deferred(false)
	self.visible = false
	shieldActive = false
	sp_current = 0.1
	await get_tree().create_timer(3).timeout
	shieldAlive()
	
func shieldAlive(): #Instant on shield
	shield_area.set_monitoring.call_deferred(true)
	shield_area.set_monitorable.call_deferred(true)
	self.visible = true
	shieldActive = true

func damageTimeout(): #Turns off shield regen for 1 second after damage taken
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
