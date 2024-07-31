extends Control

@onready var hp_current
@onready var hp_max
@onready var sp_current
@onready var sp_max

@onready var hud = $"."
@onready var player = $"../../Player"
@onready var laser = $"../../Player/Laser"
@onready var healthBar = $HealthBar
@onready var shieldBar = $ShieldBar
@onready var coords = $Coords

var shieldActive:bool = false

@onready var score = $Score:
	set(value):
		score.text = "SCORE: " + str(value)

var uilife_scene = preload("res://scenes/ui_life.tscn")

@onready var lives = $Lives


func init_lives(amount):
	for ul in lives.get_children():
		ul.queue_free()
	for i in amount:
		var ul = uilife_scene.instantiate()
		lives.add_child(ul)

func _process(delta):
	$Variable.text = "Last Col: " + str(round(player.energy_current))
	
	healthBar.value = player.hp_current
	healthBar.max_value = player.hp_max
	if is_instance_valid(get_node("../../Player/playerShield")):
		var shield = get_node("../../Player/playerShield")
		shieldBar.value = shield.sp_current
		shieldBar.max_value = shield.sp_max
		
	coords.text = str(round(player.global_position))
		
		
func _input(event):
	if event.is_action_pressed("toggleHUD"):
		self.visible = !self.visible
		
		
func _on_shield_ready():
	var shield = get_node("../../Player/Shield")
	shieldActive = true
