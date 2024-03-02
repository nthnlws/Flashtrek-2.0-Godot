extends VBoxContainer

var count: int = 0
var max_index: int = 0

onready var top_score_label = $MarginContainer2/TopScore


func _ready() -> void:
	var top_score = HighScoreManager.get_top_score()
	max_index = HighScoreManager.get_number_of_high_scores() - 1
	top_score_label.display_specific_score(1, top_score[1], top_score[0], false)
	$Timer.start(5.0)


func update_display() -> void:
	var labels = $MarginContainer3/Scores.get_children()
	var child_count = $MarginContainer3/Scores.get_child_count()
	for i in $MarginContainer3/Scores.get_child_count():
		var index: int = i + count * child_count + 1
		if index > max_index:
			count = 0
			$Timer.start(6.0)
			return
		# See HighScoreLabel
		labels[i].display_specific_score(
			index + 1,
			HighScoreManager.high_scores[index][1],
			HighScoreManager.high_scores[index][0]
		)
	count += 1
	$Timer.start(6.0)


func _on_Timer_timeout() -> void:
	update_display()
