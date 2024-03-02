extends Area2D

var id: String = "bouncing"


func _on_BouncingBullletPowerup_body_entered(body: Node) -> void:
	if body is Ship2D:
		body.apply_bouncing_bullet_powerup()
		EventBus.emit_signal("powerup_collected", id)
		queue_free()
