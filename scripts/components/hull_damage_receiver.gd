extends Area2D
class_name HullDamageReceiver

signal recieved_damage(hit_event:HitEvent)
signal set_aggression(shooter)


func can_recieve_damage(hit_event:HitEvent):
	hit_event.hit_hull = true
	
	if hit_event.get_shooter_node() != get_parent():
		recieved_damage.emit(hit_event)
		
		if get_parent() is FactionCharacter:
			var shooter = hit_event.get_shooter_node()
			if shooter.faction != get_parent().faction:
				set_aggression.emit(shooter)
