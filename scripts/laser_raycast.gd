extends RayCast2D

@onready var parent: Laser = $".."


func _physics_process(delta):
	force_raycast_update()

	# Collision logic
	if is_colliding():
		var collider: Object = get_collider()

		if collider.is_in_group("enemy_shield"):
			parent.target = collider
			parent.target_point = to_local(get_collision_point())
		elif collider.is_in_group("enemy_hitbox"):
			parent.target = collider
			parent.target_point = to_local(get_collision_point())
	else:
		parent.target = null
