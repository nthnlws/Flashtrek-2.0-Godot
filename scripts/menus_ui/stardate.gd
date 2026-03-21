extends TextButton
class_name StardateLabel


func _ready() -> void:
	super()
	update_stardate()


func update_stardate() -> void:
	# Calculate the current Stardate
	var current_stardate: float = Utility.get_federation_date()
	
	# Format the text for the label, showing one decimal place
	text = "Stardate: %.1f" % current_stardate
