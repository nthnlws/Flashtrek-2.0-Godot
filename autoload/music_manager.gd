extends Node

var current_track: AudioStreamPlayer


func _ready() -> void:
	current_track = get_node("Title")
	$Tween.interpolate_property(
		current_track, "volume_db", -80, 0.0, 5.0, Tween.TRANS_CUBIC, Tween.EASE_OUT, 0.0
	)
	$Tween.start()
	yield($Tween, "tween_started")
	current_track.play()


func _change_track_to(
	track: String = "Title", fade_out_time: float = 1.0, fade_in_time: float = 0.1
) -> void:
	# check track requested is a valid node
	if get_node_or_null(track) == null:
		return
	# fade out the track playing
	$Tween.interpolate_property(
		current_track,
		"volume_db",
		0.0,
		-80.0,
		fade_out_time,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT,
		0.0
	)
	$Tween.start()
	yield($Tween, "tween_started")
	# set the new current track
	current_track = get_node(track)
	# fade in the new track, ensuring it starts when the last tween will have finished
	$Tween.interpolate_property(
		current_track,
		"volume_db",
		-80,
		0.0,
		fade_in_time,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT,
		fade_out_time
	)
	$Tween.start()
	yield($Tween, "tween_started")
	current_track.play()
