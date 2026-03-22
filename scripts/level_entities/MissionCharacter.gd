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
	move_to_target(movement_target_position, delta)


func move_to_target(target_pos: Vector2, delta: float, speed_mult: float = 1.0) -> void:
	var to_target: Vector2 = target_pos - global_position
	var angle_diff: float = wrapf(to_target.angle() - global_rotation, -PI, PI)
	_rotate_toward_target(angle_diff, delta)
	velocity = to_target.normalized() * move_speed
	move_and_slide()
