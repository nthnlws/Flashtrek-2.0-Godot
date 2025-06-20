extends Node

func _ready() -> void:
	SignalBus.entering_new_system.connect(single_player_game)
	if OS.get_name() == "Windows":
			DiscordManager.main_menu()


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
	DiscordRPC.details = "In " + Navigation.currentSystem + " system"
	#DiscordRPC.state = 
	DiscordRPC.large_image = "icon"
	DiscordRPC.large_image_text = "FlashTrek 2.0"
	DiscordRPC.small_image = "enterprisetos"
	DiscordRPC.small_image_text = "Player Ship"

	#DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) # "mm:ss elapsed"

	DiscordRPC.refresh() # Always refresh after changing the values!
