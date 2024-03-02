extends Area2D

var id: String = "health"


func _on_Health_body_entered(body: Node) -> void:
	if body is Ship2D:
		body.apply_health_powerup(5)
		EventBus.emit_signal("powerup_collected", id)
		queue_free()
