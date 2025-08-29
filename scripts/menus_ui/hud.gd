extends Control

@onready var missions: Control = $Missions
@onready var comms_ui: Control = $Comms_UI
@onready var message_ui: Control = $message_UI

@onready var health_indicator: Control = %health_indicator
@onready var player = get_tree().get_first_node_in_group("player")

@onready var fps: Label = %FPS
@onready var coords: Label = %Coords


var shieldActive:bool = false

@onready var score_label: Label = %Score
var current_score: int = 0


func _ready() -> void:
	# Signal connections
	SignalBus.updateScore.connect(updateScore)
	
	SignalBus.playerHealthChanged.connect(_on_player_health_changed)
	SignalBus.playerMaxHealthChanged.connect(_on_player_max_health_changed)
	SignalBus.playerMaxShieldChanged.connect(_on_player_max_shield_changed)
	SignalBus.playerShieldChanged.connect(_on_player_shield_changed)
	
	SignalBus.playerDied.connect(close_menus)


func _process(delta: float) -> void:
	if player:
		coords.text = str(Vector2i(player.global_position))
		fps.text = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))


func _on_player_health_changed(hp_current: float) -> void:
	health_indicator.update_hitbox_health(hp_current)


func _on_player_max_health_changed(hp_max:float) -> void:
	health_indicator.update_hitbox_max(hp_max)


func _on_player_shield_changed(sp_current: float) -> void:
	health_indicator.update_shield_health(sp_current)


func _on_player_max_shield_changed(sp_max:float) -> void:
	health_indicator.update_shield_max(sp_max)


func _on_shield_ready() -> void:
	shieldActive = true


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") and Navigation.in_galaxy_warp == false:
		SignalBus.UIclickSound.emit()
		SignalBus.pause_menu_clicked.emit()


func close_menus() -> void:
	comms_ui.close_comms()
	missions.close_menu()
	message_ui.close_pop_menu()


func updateScore(reward:int) -> void:
	current_score += reward
	var new_score: String = "Total Score: " + str(current_score)
	score_label.text = new_score
