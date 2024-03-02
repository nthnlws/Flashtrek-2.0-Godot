extends ProgressBar


func update(new_time: float = 0.0) -> void:
	if new_time == 3.0:
		$Tween.interpolate_property(
			self, "value", value, new_time, 0.2, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.0
		)
		$Tween.start()
	else:
		value = new_time
