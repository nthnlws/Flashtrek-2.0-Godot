extends NeutralCharacter
class_name MissionCharacter

var movement_target_position: Vector2 = Vector2.ZERO
var is_hostile: bool = false


func explode(hit_event:HitEvent = HitEvent.new()) -> void:
	shield.turnShieldOff()
	sprite.visible = false
	
	SignalBus.missionCharacterDied.emit(self)
	
	collision_shape.set_deferred("disabled", true)
	%ship_explosion.play()
	
	animation.visible = true
	animation.play("explode")
	await animation.animation_finished
	
	queue_free()


func setMovementState(delta:float) -> void:
	VectorMovement(delta)


func VectorMovement(delta:float) -> void:
	moveToTarget(movement_target_position, delta)


func moveToTarget(targetPos:Vector2, delta: float) -> void:
	velocity = (targetPos - self.global_position).normalized() * move_speed
	var angle_diff:float = calc_angle(targetPos, delta)
	look_at_target(targetPos, angle_diff, delta)
	move_and_slide()
