extends Control

var hp_current
var hp_max
var sp_current
var sp_max

@onready var player: Player = SignalBus.player
@onready var playerShield: Sprite2D = SignalBus.player.get_node("playerShield")
@onready var camera: Camera2D = SignalBus.player.get_node("Camera2D")

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

	set_bar_maxes() # Initializes bar values

func _process(delta):
	%Variable.text = "Zoom: " + str(camera.zoom)
	%Coords.text = str(round(player.global_position))
	
	%FPS.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))


func _on_player_health_changed(hp_current):
	%HealthBar.value = hp_current
	
func _on_player_shield_changed(sp_current):
	%ShieldBar.value = sp_current

func _on_player_energy_changed(energy_current):
	%EnergyBar.value = energy_current
		
func _on_shield_ready():
	shieldActive = true


func set_bar_maxes():
	%HealthBar.max_value = player.max_HP
	%ShieldBar.max_value = playerShield.max_SP
	%EnergyBar.max_value = player.max_energy
	%HealthBar.value = player.hp_current
	%ShieldBar.value = playerShield.sp_current
	%EnergyBar.value = player.energy_current


func _on_texture_rect_gui_input(event):
	if event.is_action_pressed("left_click"):
		SignalBus.pause_menu_clicked.emit()

