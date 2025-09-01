extends baseShield
class_name EnemyShield

signal took_damage


func _process(delta: float) -> void:
	if shieldActive and sp_current <= sp_max and damageTime == false:
		regen_shield(delta)
	
	if sp_current < 0.1:
		turnShieldOff()


func take_damage(damage:float, hit_pos:Vector2, shooter:Node) -> void:
	damageTimeout()
	sp_current -= damage
	
	took_damage.emit(shooter)
	Utility.createDamageIndicator(damage, Utility.damage_blue, hit_pos)
	
	if sp_current <= 0:
		turnShieldOff()
