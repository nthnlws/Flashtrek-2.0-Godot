extends ProgressBar


func update(new_time: float = 0.0) -> void:
	if new_time == 8.0:
		step = 0.01
		$Tween.interpolate_property(
			self, "value", value, new_time, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.0
		)
		$Tween.start()
	elif $Tween.is_active():
		pass
	else:
		step = 1.0
		value = new_time
