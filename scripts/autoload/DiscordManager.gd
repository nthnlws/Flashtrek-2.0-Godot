extends Node

func _ready() -> void:
	if OS.get_name() == "Windows":
		DiscordManager.single_player_game()
		
func  _process(delta) -> void:
	DiscordRPC.run_callbacks()
	
	
func main_menu() -> void:
	#print("Discord Main menu")
	DiscordRPC.app_id = 1273082300866891807 # Application ID
	DiscordRPC.details = "In Main menu"
	DiscordRPC.large_image = "icon"
	DiscordRPC.large_image_text = "FlashTrek 2.0"
	
	DiscordRPC.state = ""
	DiscordRPC.small_image = ""
	DiscordRPC.small_image_text = ""

	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "mm:ss elapsed"

	DiscordRPC.refresh() # Always refresh after changing the values!
	
	
func single_player_game() -> void:
	#print("Discord SP")
	DiscordRPC.details = "Where no man has gone before"
	DiscordRPC.state = "In Solarus"
	DiscordRPC.large_image = "icon"
	DiscordRPC.large_image_text = "FlashTrek 2.0"
	DiscordRPC.small_image = "enterprisetos"
	DiscordRPC.small_image_text = "Player Ship"

	#DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "mm:ss elapsed"

	DiscordRPC.refresh() # Always refresh after changing the values!
