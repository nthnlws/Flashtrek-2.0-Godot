extends Node2D

var is_out:bool = false
var _active_tween:Tween
const slide_time_sec:float = 0.65

func slide_saves_container_out() -> void:
	if _active_tween:
		_active_tween.kill()
	
	is_out = true
	_active_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(self, "position", Vector2(0, 0), slide_time_sec)

func slide_saves_container_in() -> void:
	if _active_tween:
		_active_tween.kill()
	
	is_out = false
	_active_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(self, "position", Vector2(-390, 0), slide_time_sec)
