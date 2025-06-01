extends Control

@onready var player: Player = Utility.mainScene.player
@onready var playerShield: Sprite2D = player.get_node("playerShield")
@onready var camera: Camera2D = player.get_node("Camera2D")

@onready var missions: Control = $Missions
@onready var comms_ui: Control = $Comms_UI
@onready var message_ui: Control = $message_UI

var shieldActive:bool = false

@onready var score_label: Label = %Score
var current_score: int = 0


func _ready() -> void:
	# Signal connections
	SignalBus.updateScore.connect(updateScore)
	SignalBus.playerHealthChanged.connect(_on_player_health_changed)
	SignalBus.playerShieldChanged.connect(_on_player_shield_changed)
	SignalBus.playerEnergyChanged.connect(_on_player_energy_changed)
	
	SignalBus.playerDied.connect(close_menus)

	set_bar_maxes() # Initializes bar values

func _process(delta: float) -> void:
	%Variable.text = "Zoom: " + str(snapped(camera.zoom,Vector2(0.01, 0.01)))
	%Coords.text = str(round(player.global_position))
	
	%FPS.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))


func _on_player_health_changed(hp_current: float) -> void:
	%HealthBar.value = hp_current
	
func _on_player_shield_changed(sp_current: float) -> void:
	%ShieldBar.value = sp_current

func _on_player_energy_changed(energy_current: float) -> void:
	%EnergyBar.value = energy_current
		
func _on_shield_ready() -> void:
	shieldActive = true


func set_bar_maxes() -> void:
	%HealthBar.max_value = player.max_HP
	%ShieldBar.max_value = playerShield.base_max_SP
	%EnergyBar.max_value = player.max_energy
	%HealthBar.value = player.hp_current
	%ShieldBar.value = playerShield.sp_current
	%EnergyBar.value = player.energy_current


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") and Utility.mainScene.in_galaxy_warp == false:
		Utility.play_click_sound(4)
		SignalBus.pause_menu_clicked.emit()

func close_menus() -> void:
	comms_ui.close_comms()
	missions.close_menu()
	message_ui.close_pop_menu()

func updateScore(reward:int) -> void:
	current_score += reward
	var new_score: String = "Score: " + str(current_score)
	score_label.text = new_score
