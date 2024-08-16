extends Node

var player: Node = null
var HUD: Node = null
var pauseMenu: Node = null
var levelBorders: Node = null
var settingsButton: Node = null
var enemies = []


func _ready():
	call_deferred("connect_signals")
	
	
func connect_signals():
	player.connect("playerHealthChanged", Callable(HUD, "_on_player_health_changed"))
	player.connect("playerEnergyChanged", Callable(HUD, "_on_player_energy_changed"))
	player.get_node("playerShield").connect("playerShieldChanged", Callable(HUD, "_on_player_shield_changed"))
	settingsButton.connect("menu_clicked", Callable(pauseMenu, "toggle_menu"))
	pauseMenu.connect("world_reset", Callable(self, "_reset_node_references"))
	
func _reset_node_references():
	HUD._reset_node_references()
	for enemy in enemies:
		enemy._reset_node_references()
	
