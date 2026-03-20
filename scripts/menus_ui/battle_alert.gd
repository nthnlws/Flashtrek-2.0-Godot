extends TextureRect

@onready var flashing_anim: AnimationPlayer = $flashing_anim
@onready var timer: Timer = $Timer

var disabled: bool = false

func _ready() -> void:
	SignalBus.entering_combat.connect(activate_red_alert)
	SignalBus.exited_combat.connect(deactivate_alert)
	SignalBus.galaxy_warp_finished.connect(_handle_entering_new_system)
	SignalBus.warningsDisabled.connect(func(check_value): disabled = check_value)
	
	modulate = Color("ff000000")


func deactivate_alert() -> void:
	if flashing_anim.is_playing():
		flashing_anim.stop()
	if !timer.is_stopped():
		timer.stop()

func activate_red_alert() -> void:
	if disabled: return
	
	if flashing_anim.is_playing():
		flashing_anim.stop()
	
	flashing_anim.play("red_alert")

func activate_yellow_alert() -> void:
	if disabled: return
	# Reset state
	if flashing_anim.is_playing():
		flashing_anim.stop()
	if !timer.is_stopped():
		timer.stop()
	
	timer.start()
	flashing_anim.play("yellow_alert")
	await timer.timeout
	deactivate_alert()


func _handle_entering_new_system(system_data:SystemData) -> void:
	if _in_enemy_system(system_data):
			await get_tree().create_timer(3.0).timeout
			activate_yellow_alert()


func _in_enemy_system(system_data:SystemData):
	# If either party is neutral
	if (system_data.faction == Utility.FACTION.NEUTRAL
		or LevelManager.player.faction == Utility.FACTION.NEUTRAL):
			return false
	# If player faction does not match system
	if LevelManager.player.faction != system_data.faction:
		return true
	# Player faction matches system
	else: return false 
