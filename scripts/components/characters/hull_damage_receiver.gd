extends Area2D
class_name HullDamageReceiver

signal recieved_damage(hit_event:HitEvent)


func can_recieve_damage(hit_event:HitEvent):
	hit_event.hit_hull = true
	
	if hit_event.get_shooter_node() != get_parent():
		recieved_damage.emit(hit_event)
