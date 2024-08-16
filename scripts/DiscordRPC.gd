extends Node
func _ready():
	DiscordRPC.app_id = 1273082300866891807 # Application ID
	DiscordRPC.details = "Where no man has gone before"
	DiscordRPC.state = "In Solarus"
	DiscordRPC.large_image = "icon" # Image key from "Art Assets"
	DiscordRPC.large_image_text = "FlashTrek 2.0"
	DiscordRPC.small_image = "TOSenterprise" # Image key from "Art Assets"
	DiscordRPC.small_image_text = "Player Ship"

	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "02:46 elapsed"
	# DiscordRPC.end_timestamp = int(Time.get_unix_time_from_system()) + 3600 # +1 hour in unix time / "01:00:00 remaining"

	DiscordRPC.refresh() # Always refresh after changing the values!
