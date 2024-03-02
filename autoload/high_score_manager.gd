extends Node

# limit for the number of scores on the high score list
const MAX_HIGH_SCORE_COUNT = 100

# holds the current score for the game in progress
var current_score: int = 0

var high_scores: Array = [
	[200, "Jonathan"],
	[200, "Steve"],
	[200, "Andy"],
	[200, "Pete"],
	[180, "Jim"],
	[160, "Steve"],
	[150, "Steve"],
	[140, "Pete"],
	[130, "Pete"],
	[120, "Dave"],
	[110, "Dave"],
	[100, "Tim"],
	[90, "Tim"],
	[80, "Andy"],
	[70, "Andy"],
	[60, "Andy"],
	[50, "Andy"],
	[40, "Andy"],
	[30, "Andy"],
	[20, "Andy"],
	[10, "Andy"]
]


func _ready() -> void:
	high_scores.sort_custom(self, "sort_by_score")


func is_new_high_score(score: int = 0) -> bool:
	for entry in high_scores:
		if score > entry[0]:
			return true
	# can have 10 high scores so if lower than defaults add
	if high_scores.size() < MAX_HIGH_SCORE_COUNT:
		return true

	return false


# add a high score to the list
func add_high_score(score: int = 0, by: String = "Anon") -> void:
	var new_high_score: Array = [score, by]

	high_scores.append(new_high_score)
	high_scores.sort_custom(self, "sort_by_score")
	# keep high score size same.
	if high_scores.size() > MAX_HIGH_SCORE_COUNT:
		high_scores.resize(MAX_HIGH_SCORE_COUNT)

	# at this point reset the current score to 0
	current_score = 0


func get_top_score() -> Array:
	return high_scores[0]


func get_number_of_high_scores() -> int:
	return high_scores.size()


# Custom sort for the high score list.
# Sorts the scores numerically in the event of a tie, scores are sorted alphabetically by name.
static func sort_by_score(a, b) -> bool:
	if a[0] > b[0]:
		return true

	if a[0] == b[0]:
		return a[1] < b[1]

	return false
