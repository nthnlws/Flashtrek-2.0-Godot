extends Shield


func _process(delta):
	if shieldActive and sp_current <= sp_max and damageTime == false:
		regen_shield(delta)


func take_damage(damage, shooter, projectile):
	if shooter != "enemy":
		damageTimeout()
		
		sp_current -= damage
		
		var spawn = projectile.create_damage_indicator(damage, self.global_position, $shield_area.name)
		projectile.kill_projectile($shield_area.name)
		$Hitmarkers.add_child(spawn)
		
		
		if sp_current <= 0:
			shieldDie()
