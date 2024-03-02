extends Control


func update(new_hp: float = 1.0) -> void:
	#Incase of double hit, stop the tween if it is already in progress
	$Tween.stop_all()

	if new_hp < $Over.value:
		# set the over bar to the new value immediately when losing hp
		$Over.value = new_hp
		# tween the under value to the new_hp, having a slight delay before.
		$Tween.interpolate_property(
			$Under, "value", $Under.value, new_hp, 0.5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 1.0
		)
		$Tween.start()
	else:
		$Tween.interpolate_property(
			$Under, "value", $Under.value, new_hp, 0.1, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0.0
		)
		$Tween.interpolate_property(
			$Over, "value", $Over.value, new_hp, 0.25, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 1.0
		)
		$Tween.start()
