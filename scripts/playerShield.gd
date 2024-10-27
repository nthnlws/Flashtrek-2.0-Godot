extends Sprite2D


var damageTime:bool = false
@onready var shieldActive:bool = true
@export var regen_speed:float = 2.5

@onready var trans_length:float = get_parent().trans_length
@onready var shield_area:Area2D = $shield_area

# Player shield health variables
@onready var sp_current:float = sp_max
@export var sp_max:int = 50

func _process(delta):
	if shieldActive == true and sp_current <= sp_max and damageTime == false:
		sp_current += regen_speed * delta
		sp_current = clamp(sp_current, 0, sp_max)
		SignalBus.playerShieldChanged.emit(sp_current)
	if get_parent().warping_active == true and shieldActive == true:
		#Forces shieldActive to false when player is warping
		shieldActive = false
	if sp_current <= 0: shieldDie()
	
	if GameSettings.playerShield != null:
		if GameSettings.playerShield == false:
			visible = false
			shield_area.collision_layer = 0
			shield_area.collision_mask = 0
			SignalBus.playerShieldChanged.emit(0)
		elif GameSettings.playerShield == true && shieldActive == true:
			visible = true
			shield_area.collision_layer = 2
			shield_area.collision_mask = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)
			SignalBus.playerShieldChanged.emit(sp_current)
		

func fadeout(speed): # Fades shield to 0 Alpha
	match speed:
		"INSTANT":
			modulate.a = 0  # Instantly set alpha to 0
			shield_area.set_monitoring(false)
			shield_area.set_monitorable(false)
			shieldActive = false
		"SMOOTH":
			var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
			tween.tween_property(self, "modulate:a", 0, trans_length)
			await tween.finished
			shield_area.set_monitoring.call_deferred(false)
			shield_area.set_monitorable.call_deferred(false)
			shieldActive = false

func fadein(speed): # Fades shield in to 255 Alpha
	match speed:
		"INSTANT":
			modulate.a = 1  # Instantly set alpha to 1 (255 equivalent)
			shield_area.set_monitoring(true)
			shield_area.set_monitorable(true)
			shieldActive = true
		"SMOOTH":
			var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
			tween.tween_property(self, "modulate:a", 1, trans_length)
			await tween.finished
			shield_area.set_monitoring.call_deferred(true)
			shield_area.set_monitorable.call_deferred(true)
			shieldActive = true

	
func shieldDie(): #Instantly turns off shield when health goes to 0
	shield_area.set_monitoring.call_deferred(false)
	shield_area.set_monitorable.call_deferred(false)
	self.visible = false
	shieldActive = false
	sp_current = 0.0001
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
	
func _on_shield_area_entered(area): #Torpedo damage
	if area.is_in_group("projectile") and area.shooter != "player":
		area.queue_free()
		if GameSettings.unlimitedHealth == false:
			var damage_taken = area.damage
			sp_current -= damage_taken
			SignalBus.playerShieldChanged.emit(sp_current)
		damageTimeout()
	elif area.is_in_group("enemy"):
		pass
		#get_parent().die()
