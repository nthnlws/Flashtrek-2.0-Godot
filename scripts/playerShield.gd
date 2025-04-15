extends Shield

# Player shield health variables
@export var base_max_SP:int = 150
var max_SP:int = 150:
	get:
		return PlayerUpgrades.ShieldAdd + (base_max_SP * PlayerUpgrades.ShieldMult)



func _process(delta):
	if sp_current <= max_SP and damageTime == false:
		regen_shield(delta)
		SignalBus.playerShieldChanged.emit(sp_current)
	if get_parent().warping_active == true and shieldActive == true:
		#Forces shieldActive to false when player is warping
		shieldActive = false

func take_damage(damage:float, shooter:String, projectile:Projectile):
	if shooter != "player":
		damageTimeout() # Turn off shield regen for period
		sp_current -= damage # Take damage
		SignalBus.playerShieldChanged.emit(sp_current) # Update HUD
		var spawn = projectile.create_damage_indicator(damage, $shield_area.name)
		projectile.kill_projectile($shield_area.name)
		$Hitmarkers.add_child(spawn)
		
		if sp_current <= 0:
			shieldDie()
		
