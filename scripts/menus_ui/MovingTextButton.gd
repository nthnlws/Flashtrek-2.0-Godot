extends TextButton
class_name MenuTextButton

@onready var texture_rect: TextureRect = $".."

var active_tweens:Array[Tween] = []

func _on_mouse_entered() -> void:
	super()
	for tween:Tween in active_tweens:
		tween.stop()
		
	var tween:Tween = create_tween()
	tween.tween_property(texture_rect, "position", Vector2.ZERO, 0.2)
	active_tweens.append(tween)


func _on_mouse_exited() -> void:
	super()
	for tween:Tween in active_tweens:
		tween.stop()
		
	var tween:Tween = create_tween()
	tween.tween_property(texture_rect, "position", Vector2(-36.1, 0.0), 0.2)
	active_tweens.append(tween)
