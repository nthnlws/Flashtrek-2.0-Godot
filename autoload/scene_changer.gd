extends CanvasLayer


func change_scene(next_scene_path: String, delay: float = 1.0):
	yield(get_tree().create_timer(delay), "timeout")
	$AnimationPlayer.play("fade")
	yield($AnimationPlayer, "animation_finished")
	get_tree().change_scene(next_scene_path)
	# unpause the game if it is paused
	if get_tree().paused:
		get_tree().paused = !get_tree().paused
	$AnimationPlayer.play_backwards("fade")
	yield($AnimationPlayer, "animation_finished")
