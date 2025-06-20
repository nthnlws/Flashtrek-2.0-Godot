extends Shield

# Player shield health variables
@export var base_max_SP:int = 150:
	set(value):
		base_max_SP = value
		SignalBus.playerMaxShieldChanged.emit(value)


func _process(delta: float) -> void:
	if sp_current <= base_max_SP and damageTime == false:
		regen_shield(delta)
		SignalBus.playerShieldChanged.emit(sp_current)
	if get_parent().overdrive_active == true and shieldActive == true:
		#Forces shieldActive to false when player is warping
		shieldActive = false

func take_damage(damage:float, hit_pos: Vector2) -> void:
	if Utility.mainScene.in_galaxy_warp == false:
		damageTimeout() # Turn off shield regen for period
		sp_current -= damage # Take damage
		Utility.createDamageIndicator(damage, Utility.damage_blue, hit_pos)
		
		if sp_current <= 0:
			shieldDie()
		
		SignalBus.playerShieldChanged.emit(sp_current) # Update HUD
