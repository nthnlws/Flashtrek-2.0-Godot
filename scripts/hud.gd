extends Control

var hp_current
var hp_max
var sp_current
var sp_max

signal menu_clicked

@onready var player = Global.player
@onready var playerShield = Global.player.get_node("playerShield")
@onready var camera = Global.player.get_node("Camera2D")

var shieldActive:bool = false

@onready var score = %Score:
	set(value):
		score.text = "SCORE: " + str(value)

var uilife_scene = preload("res://scenes/ui_life.tscn")

	
func _ready():
	Global.HUD = self
	
	set_bar_maxes() # Initializes bar values

func _process(delta):
	%Variable.text = "Zoom: " + str(camera.zoom)
	%Coords.text = str(round(player.global_position))
	
	%FPS.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))
	


func _on_player_health_changed(hp_current):
	$HealthBar.value = hp_current
	
func _on_player_shield_changed(sp_current):
	%ShieldBar.value = sp_current

func _on_player_energy_changed(energy_current):
	%EnergyBar.value = energy_current
		
func _on_shield_ready():
	var shield = get_node("../../Level/Player/Shield")
	shieldActive = true
	
func init_lives(amount):
	for ul in %Lives.get_children():
		ul.queue_free()
	for i in amount:
		var ul = uilife_scene.instantiate()
		%Lives.add_child(ul)
		
func set_bar_maxes():
	%HealthBar.max_value = player.hp_max
	%ShieldBar.max_value = playerShield.sp_max
	%EnergyBar.max_value = player.energy_max
	%HealthBar.value = player.hp_current
	%ShieldBar.value = playerShield.sp_current
	%EnergyBar.value = player.energy_current


func _on_texture_rect_gui_input(event):
	if event.is_action_pressed("left_click"):
		menu_clicked.emit()
