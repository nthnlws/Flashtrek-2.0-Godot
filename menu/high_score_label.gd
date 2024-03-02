class_name HighScoreLabel

extends HBoxContainer


func display_specific_score(n: int = 0, id: String = "", score: int = 0, fade: bool = true) -> void:
	$MC/Number.text = str(n) + "."
	$ID.text = id
	$Score.text = str(score)
	#tween the appearence of the text, from left to right
	$Tween.interpolate_property($MC/Number, "percent_visible", 0.0, 1.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	$Tween.interpolate_property($ID, "percent_visible", 0.0, 1.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	$Tween.interpolate_property($Score, "percent_visible", 0.0, 1.0, 0.2)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	if fade:
		fade_out()


func fade_out() -> void:
	# tween the fade of the text - delayed by 4s to give a nice
	# sychronisation with the refresh of the high score table
	$Tween.interpolate_property(
		$MC/Number, "modulate:a", 1.0, 0.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 4.0
	)
	$Tween.interpolate_property(
		$ID, "modulate:a", 1.0, 0.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 4.0
	)
	$Tween.interpolate_property(
		$Score, "modulate:a", 1.0, 0.0, 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 4.0
	)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	# clear all text ready for next display
	clear_all_text()


# clears the text from the high score lable and sets the modulate to full
func clear_all_text() -> void:
	$MC/Number.set_text("")
	$MC/Number.percent_visible = 0.0
	$MC/Number.modulate.a = 1.0
	$ID.set_text("")
	$ID.percent_visible = 0.0
	$ID.modulate.a = 1.0
	$Score.set_text("")
	$Score.percent_visible = 0.0
	$Score.modulate.a = 1.0
