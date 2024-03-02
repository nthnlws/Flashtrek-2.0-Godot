extends Area2D

var id: String = "laser"


func _on_LaserPowerup_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.set_laser_available(true)
		EventBus.emit_signal("powerup_collected", id)
		queue_free()
