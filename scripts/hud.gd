extends Control

@onready var hp_current
@onready var hp_max
@onready var sp_current
@onready var sp_max

@onready var player = Global.player
@onready var playerShield = Global.player.get_node("playerShield")
@onready var laser = Global.player.get_node("Laser")
@onready var camera = Global.player.get_node("Camera2D")
@onready var healthBar = $HealthBar
@onready var shieldBar = $ShieldBar
@onready var coords = $Coords
@onready var energyBar = $EnergyBar
@onready var lives = $Lives
@onready var variable = $Variable

var shieldActive:bool = false

@onready var score = $Score:
	set(value):
		score.text = "SCORE: " + str(value)

var uilife_scene = preload("res://scenes/ui_life.tscn")

func _reset_node_references():
	var playerShield = Global.player.get_node("playerShield")
	var laser = Global.player.get_node("Laser")
	var camera = Global.player.get_node("Camera2D")
	
func _ready():
	Global.HUD = self
	
	# Sets value bars
	set_bar_maxes() # Initializes bar values

func _process(delta):
	variable.text = "Zoom: " + str(camera.zoom)
	coords.text = str(round(player.global_position))

#func _unhandled_input(event):
	#if event.is_action_pressed("toggleHUD"):
		#self.visible = !self.visible
		
func _on_player_health_changed(hp_current):
	healthBar.value = hp_current
	
func _on_player_shield_changed(sp_current):
	shieldBar.value = sp_current

func _on_player_energy_changed(energy_current):
	energyBar.value = energy_current
		
func _on_shield_ready():
	var shield = get_node("../../Level/Player/Shield")
	shieldActive = true
	
func init_lives(amount):
	for ul in lives.get_children():
		ul.queue_free()
	for i in amount:
		var ul = uilife_scene.instantiate()
		lives.add_child(ul)
		
func set_bar_maxes():
	healthBar.max_value = player.hp_max
	shieldBar.max_value = playerShield.sp_max
	energyBar.max_value = player.energy_max
	healthBar.value = player.hp_current
	shieldBar.value = playerShield.sp_current
	energyBar.value = player.energy_current
