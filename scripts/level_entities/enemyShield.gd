extends baseShield
class_name EnemyShield


func _process(delta: float) -> void:
	if shieldActive and sp_current <= sp_max and damageTime == false:
		regen_shield(delta)
	
	if sp_current < 0.1:
		shieldDie()


func take_damage(damage:float, hit_pos:Vector2) -> void:
	damageTimeout()
	sp_current -= damage
	
	Utility.createDamageIndicator(damage, Utility.damage_blue, hit_pos)
	
	if sp_current <= 0:
		shieldDie()
