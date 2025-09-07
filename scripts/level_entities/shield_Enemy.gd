extends baseShield
class_name EnemyShield

signal took_damage

func _process(delta: float) -> void:
	if shieldActive and sp_current <= sp_max and damageTime == false:
		regen_shield(delta)
	
	if sp_current < 0.1:
		turnShieldOff()

func take_damage(hit_event:HitEvent) -> void:
	super(hit_event)
	took_damage.emit(hit_event.get_shooter_node())
