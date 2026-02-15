extends Node
class_name ControlEffectsComponent

@export var ease_type: Tween.EaseType
@export var trans_type: Tween.TransitionType
@export var anim_duration: float = 0.15
@export var scale_amount: Vector2 = Vector2(1.25, 1.25)
@export var rotation_amount: float = 3.0

@onready var parent: Control = get_parent()

var tween: Tween

func _ready() -> void:
	MissionManager.Reputation.reputation_total_changed.connect(on_faction_score_changed)
	parent.pivot_offset_ratio = Vector2(0.5, 0.5)


# Debug test for animation
#func _input(event: InputEvent) -> void:
	#if event is InputEventKey:
		#if event.is_action_pressed("F9"):
			#on_faction_score_changed(Utility.FACTION.FEDERATION, 10)


func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(ease_type).set_trans(trans_type).set_parallel(true)


func on_faction_score_changed(faction:Utility.FACTION, score:int) -> void:
	reset_tween()
	tween.tween_property(parent, "scale", scale_amount, anim_duration)
	tween.tween_property(parent, "rotation_degrees", rotation_amount * [-1, 1].pick_random(), anim_duration)
	await tween.finished
	reset_tween()
	tween.tween_property(parent, "scale", Vector2.ONE, anim_duration)
	tween.tween_property(parent, "rotation_degrees", 0.0, anim_duration)
