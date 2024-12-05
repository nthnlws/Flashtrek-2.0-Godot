extends Sprite2D

var damageTime:bool = false
@onready var shieldActive:bool = true
@export var regen_speed:float = 2.5

@onready var trans_length:float = get_parent().trans_length
@onready var parent:Player = get_parent()
@onready var shield_area:Area2D = $shield_area

# Player shield health variables
@export var base_max_SP:int = 150
var max_SP:int = 150:
	get:
		return PlayerUpgrades.ShieldAdd + (base_max_SP * PlayerUpgrades.ShieldMult)
		
var sp_current:float = max_SP:
	set(value):
		sp_current = clamp(value, 0, max_SP)
		SignalBus.playerShieldChanged.emit(sp_current)


func _process(delta):
	if sp_current <= 0: shieldDie()
	
	if shieldActive == true and sp_current <= max_SP and damageTime == false:
		sp_current += regen_speed * delta
	if get_parent().warping_active == true and shieldActive == true:
		#Forces shieldActive to false when player is warping
		shieldActive = false
	
	
	if GameSettings.playerShield != null:
		if GameSettings.playerShield == false:
			visible = false
			shield_area.collision_layer = 0
			shield_area.collision_mask = 0
		elif GameSettings.playerShield == true && shieldActive == true:
			visible = true
			shield_area.collision_layer = 2
			shield_area.collision_mask = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)
		

# Fades shield to 0 Alpha
func fadeout(speed): # Speed = INSTANT or SMOOTH
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


# Fades shield in to 255 Alpha
func fadein(speed): # Speed = INSTANT or SMOOTH
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


func shieldDie(): #Instantly turns off shield
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
	if area.is_in_group("projectile") and area.shooter != "player" and shieldActive:
		area.kill_projectile("shield")
		
		#Create damage indicator
		var damage_taken = area.damage
		
		
		if GameSettings.unlimitedHealth == false:
			sp_current -= damage_taken
			parent.create_damage_indicator(damage_taken, area.global_position, Utility.damage_red)
		else: parent.create_damage_indicator(0, area.global_position, Utility.damage_red)
		damageTimeout()
	elif area.is_in_group("enemy"):
		pass
