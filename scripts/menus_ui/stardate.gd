extends TextButton
class_name StardateLabel

const ANCHOR_YEAR: int = 2025 
const ANCHOR_MONTH: int = 08 # October
const ANCHOR_DAY: int = 12

const ANCHOR_STARDATE_BASE: float = 4513.0


func _ready() -> void:
	super()
	update_stardate()


func update_stardate() -> void:
	# Calculate the current Stardate
	var current_stardate: float = calculate_current_stardate()
	
	# Format the text for the label, showing one decimal place
	text = "Stardate: %.1f" % current_stardate


func calculate_current_stardate() -> float:
	var anchor_dict = {
		"year": ANCHOR_YEAR,
		"month": ANCHOR_MONTH,
		"day": ANCHOR_DAY,
		"hour": 0, "minute": 0, "second": 0
	}
	var anchor_timestamp: int = Time.get_unix_time_from_datetime_dict(anchor_dict)

	# Number of seconds from 1970 to current OS time
	var now_timestamp: int = Time.get_unix_time_from_system()
	# Calculate difference in sec between anchor and now
	var seconds_since_anchor: int = now_timestamp - anchor_timestamp
	# Convert the seconds into days
	var days_since_anchor: float = seconds_since_anchor / 86400.0

	# Add days passed to base Stardate
	var final_stardate: float = ANCHOR_STARDATE_BASE + days_since_anchor
	
	return final_stardate
