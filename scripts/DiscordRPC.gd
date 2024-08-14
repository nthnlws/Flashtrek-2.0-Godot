extends Node
func _ready():
	DiscordRPC.app_id = 1273082300866891807 # Application ID
	DiscordRPC.details = "Going where no man has gone before"
	DiscordRPC.state = "In main system"
	DiscordRPC.large_image = "icon" # Image key from "Art Assets"
	DiscordRPC.large_image_text = "FlashTrek 2.0"

	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"

	DiscordRPC.refresh() # Always refresh after changing the values!
