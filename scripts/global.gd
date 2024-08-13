extends Node

var player: Node = null
var HUD: Node = null
var pauseMenu: Node = null
var levelBorders: Node = null
var settingsButton: Node = null


func _ready():
	call_deferred("connect_signals")
	
	
func connect_signals():
	player.connect("playerHealthChanged", Callable(HUD, "_on_player_health_changed"))
	player.connect("playerEnergyChanged", Callable(HUD, "_on_player_energy_changed"))
	player.get_node("playerShield").connect("playerShieldChanged", Callable(HUD, "_on_player_shield_changed"))
	settingsButton.connect("menu_clicked", Callable(pauseMenu, "toggle_menu"))
	
