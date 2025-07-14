extends Shield

func _ready() -> void:
	#Initialize HUD values
	call_deferred("initialize_hud_values")


func _process(delta: float) -> void:
	if sp_current <= sp_max and damageTime == false:
		regen_shield(delta)
	if get_parent().overdrive_active == true and shieldActive == true:
		#Forces shieldActive to false when player is warping
		shieldActive = false


func _set_shield_active(value) -> bool:
	super(value)
	# Used for setting HUD health indicator color
	if value == false:
		SignalBus.playerShieldOff.emit()
	else:
		SignalBus.playerShieldOn.emit()
	return value


func set_shield_value(value) -> float:
	super(value)
	var clamped_value: float = clamp(value, 0.0, sp_max)
	SignalBus.playerShieldChanged.emit(clamped_value)
	return clamped_value


func set_shield_max(value) -> float:
	super(value)
	value = PlayerUpgrades.ShieldAdd + (value * PlayerUpgrades.ShieldMult)
	SignalBus.playerMaxShieldChanged.emit(value)
	return value


func take_damage(damage:float, hit_pos: Vector2) -> void:
	if Utility.mainScene.in_galaxy_warp == false:
		damageTimeout() # Turn off shield regen for period
		sp_current -= damage # Take damage
		Utility.createDamageIndicator(damage, Utility.damage_blue, hit_pos)
		
		if sp_current <= 0:
			shieldDie()


func initialize_hud_values() -> void:
	SignalBus.playerMaxShieldChanged.emit(sp_max)
	SignalBus.playerShieldChanged.emit(sp_current)
