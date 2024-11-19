extends Control

var hp_current
var hp_max
var sp_current
var sp_max

@onready var player: Player = SignalBus.player
@onready var playerShield: Sprite2D = SignalBus.player.get_node("playerShield")
@onready var camera: Camera2D = SignalBus.player.get_node("Camera2D")
@onready var mission_label: RichTextLabel = %Mission

var shieldActive:bool = false

@onready var score = %Score:
	set(value):
		score.text = "SCORE: " + str(value)

	
func _ready():
	SignalBus.HUD = self
	
	# Signal connections
	SignalBus.playerHealthChanged.connect(_on_player_health_changed)
	SignalBus.playerShieldChanged.connect(_on_player_shield_changed)
	SignalBus.playerEnergyChanged.connect(_on_player_energy_changed)
	SignalBus.missionAccepted.connect(_update_mission)
	

	set_bar_maxes() # Initializes bar values

func _process(delta):
	%Variable.text = "Zoom: " + str(camera.zoom)
	%Coords.text = str(round(player.global_position))
	
	%FPS.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))
	

func _update_mission(current_mission: Dictionary):
	if current_mission.is_empty():
		mission_label.text = "Mission: None"
		mission_label.custom_minimum_size.y = 20
	else:
		var mission_text = "Mission: " + str(current_mission.get("mission_type", "Unknown")) + "\n"
		mission_text += "Target System: " + str(current_mission.get("target_system", "Unknown")) + "\n"
		mission_text += "Target Planet: " + str(current_mission.get("target_planet", "Unknown")) + "\n"
		mission_text += "Cargo: " + str(current_mission.get("cargo", "Unknown"))
		mission_label.text = mission_text
		mission_label.custom_minimum_size.y = mission_label.get_line_count() * 20
	
	
func _on_player_health_changed(hp_current):
	%HealthBar.value = hp_current
	
func _on_player_shield_changed(sp_current):
	%ShieldBar.value = sp_current

func _on_player_energy_changed(energy_current):
	%EnergyBar.value = energy_current
		
func _on_shield_ready():
	shieldActive = true


func set_bar_maxes():
	%HealthBar.max_value = player.HP_MAX
	%ShieldBar.max_value = playerShield.SP_MAX
	%EnergyBar.max_value = player.ENERGY_MAX
	%HealthBar.value = player.hp_current
	%ShieldBar.value = playerShield.sp_current
	%EnergyBar.value = player.energy_current


func _on_texture_rect_gui_input(event):
	if event.is_action_pressed("left_click"):
		SignalBus.pause_menu_clicked.emit()

