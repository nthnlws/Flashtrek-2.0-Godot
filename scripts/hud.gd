extends Control

@onready var player: Player = Utility.mainScene.player
@onready var playerShield: Sprite2D = player.get_node("playerShield")
@onready var camera: Camera2D = player.get_node("Camera2D")

@onready var missions: Control = $Missions
@onready var comms_ui: Control = $Comms_UI
@onready var message_ui: Control = $message_UI

var shieldActive:bool = false

@onready var score = %Score:
	set(value):
		score.text = "SCORE: " + str(value)

	
func _ready():
	
	# Signal connections
	SignalBus.playerHealthChanged.connect(_on_player_health_changed)
	SignalBus.playerShieldChanged.connect(_on_player_shield_changed)
	SignalBus.playerEnergyChanged.connect(_on_player_energy_changed)
	
	SignalBus.playerDied.connect(close_menus)

	set_bar_maxes() # Initializes bar values

func _process(delta):
	%Variable.text = "Zoom: " + str(snapped(camera.zoom,Vector2(0.01, 0.01)))
	%Coords.text = str(round(player.global_position))
	
	%FPS.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))


func _on_player_health_changed(hp_current: float):
	%HealthBar.value = hp_current
	
func _on_player_shield_changed(sp_current: float):
	%ShieldBar.value = sp_current

func _on_player_energy_changed(energy_current: float):
	%EnergyBar.value = energy_current
		
func _on_shield_ready():
	shieldActive = true


func set_bar_maxes():
	%HealthBar.max_value = player.max_HP
	%ShieldBar.max_value = playerShield.base_max_SP
	%EnergyBar.max_value = player.max_energy
	%HealthBar.value = player.hp_current
	%ShieldBar.value = playerShield.sp_current
	%EnergyBar.value = player.energy_current


func _on_texture_rect_gui_input(event: InputEvent):
	if event.is_action_pressed("left_click") and Utility.mainScene.in_galaxy_warp == false:
		Utility.play_click_sound(4)
		SignalBus.pause_menu_clicked.emit()

func close_menus():
	comms_ui.close_comms()
	missions.close_menu()
	message_ui.close_pop_menu()
	
