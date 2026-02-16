extends Node
class_name ControlShakeComponent

@export var ease_type: Tween.EaseType 
@export var trans_type: Tween.TransitionType
@export var anim_duration: float = 0.25
@export var scale_amount: Vector2 = Vector2(1.5, 1.5)
@export var rotation_amount: float = 5.0

@onready var parent: Control = get_parent()

var tween: Tween

func _ready() -> void:
	parent.pivot_offset_ratio = Vector2(0.5, 0.5)


## Debug test for animation
#func _input(event: InputEvent) -> void:
	#if event is InputEventKey:
		#if event.is_action_pressed("F9"):
			#trigger_shake([true, false].pick_random())


func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(ease_type).set_trans(trans_type).set_parallel(true)


func trigger_shake(increase:bool) -> void:
	reset_tween()
	tween.tween_property(parent, "scale", scale_amount, anim_duration)
	tween.tween_property(parent, "rotation_degrees", rotation_amount * [-1, 1].pick_random(), anim_duration)
	tween.tween_property(parent, "modulate", Color("00cc00") if increase else Color("ff5247"), anim_duration)
	await tween.finished
	reset_tween()
	tween.tween_property(parent, "scale", Vector2.ONE, anim_duration)
	tween.tween_property(parent, "rotation_degrees", 0.0, anim_duration)
	tween.tween_property(parent, "modulate", Color.WHITE, anim_duration)
