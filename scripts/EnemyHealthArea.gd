extends Area2D

@onready var hp_max:int = 60
@onready var hp_current:int = hp_max

func _on_enemy_area_entered(area):
	if area.is_in_group("torpedo") and area.shooter != "enemy":
		area.queue_free()
		var damage_taken = area.damage
		hp_current -= damage_taken
		if hp_current <= 0:
			get_parent().explode()
	elif area.is_in_group("enemy"):
		pass
