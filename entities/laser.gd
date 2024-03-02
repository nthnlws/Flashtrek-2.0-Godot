extends RayCast2D

var laser_speed: float = 19200.00
var max_particles: int = 25

var is_firing: bool = false setget set_is_firing, get_is_firing

var current_point: int = 0

var _damage: float = 10.0

func _ready() -> void:
	set_physics_process(is_firing)


func _physics_process(delta: float) -> void:
	cast_to += Vector2.UP * laser_speed * delta

	fire_laser()


func fire_laser() -> void:
	force_raycast_update()

	if is_colliding():
		cast_to = to_local(get_collision_point())
#		$HitParticles.global_rotation = get_collision_normal().angle()
#		$HitParticles.position = cast_to

		var body = get_collider()
		_damage_collider(body)

	var points = $Line2D.get_point_count()

	current_point += 1
	current_point %= points

	if current_point > 0:
		$Line2D.points[current_point] = cast_to * current_point / ($Line2D.get_point_count() - 1)

		var pos_delta: float = cast_to.length() / 100

		$Line2D.points[current_point].x += rand_range(-pos_delta, pos_delta)
		$Line2D.points[current_point].y += rand_range(-pos_delta, pos_delta)

	$Line2D.points[points - 1] = cast_to


#	$HitParticles.emitting = is_colliding()


func _damage_collider(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage()


func set_is_firing(value: bool) -> void:
	is_firing = value
	cast_to = Vector2.ZERO

	for p in $Line2D.get_point_count():
		$Line2D.points[p - 1] = cast_to

	set_physics_process(is_firing)


#
#	if !is_firing:
#		$HitParticles.emitting = false


func get_is_firing() -> bool:
	return is_firing
