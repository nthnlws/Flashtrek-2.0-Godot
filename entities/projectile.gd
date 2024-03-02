extends RigidBody2D

const IMPULSE_FACTOR = 1000

var direction = Vector2.UP setget set_direction

var can_bounce: bool = false setget set_can_bounce

var bounce_number: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var start_impulse: Vector2 = direction * IMPULSE_FACTOR
	apply_central_impulse(start_impulse)


func set_direction(value: Vector2 = Vector2.UP) -> void:
	direction = value


func set_can_bounce(value: bool = false) -> void:
	can_bounce = value

	if can_bounce:
		set_collision_layer_bit(1, true)
		set_collision_mask_bit(1, true)
		$Polygon2D.set_color("#ff8426")
		bounce_number = 3


func _on_RigidBody2D_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		body.take_damage()
		queue_free()

	if body is Entity2D:
		body.take_damage()

	if body.is_in_group("player"):
		body.take_damage()
		queue_free()

	bounce_number -= 1

	if bounce_number > 0:
		pass
	else:
		queue_free()


func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()
