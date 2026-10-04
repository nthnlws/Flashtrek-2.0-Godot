extends Control

@onready var close_button: TextButton = $CloseButton
@onready var comms_message: RichTextLabel = $Comms_message
@onready var timer: Timer = $Timer
@onready var fade_anim: AnimationPlayer = $fade_anim

@export var FederationHeads: Array[Texture2D]
@export var RomulanHeads: Array[Texture2D]
@export var KlingonHeads: Array[Texture2D]

var disabled: bool = false

## Messages waiting for the current one to close: {faction, text, progress}.
var _queue: Array[Dictionary] = []
var _showing_progress: bool = false
var _closing: bool = false

func _ready() -> void:
	self.visible = false
	SignalBus.galaxy_warp_finished.connect(_handle_entering_new_system)
	SignalBus.warningsDisabled.connect(func(check_value): disabled = check_value)
	MissionManager.mission_started.connect(_on_mission_phase.bind(MissionMessage.PHASE.ACCEPTED))
	MissionManager.mission_ready_for_turn_in.connect(_on_mission_phase.bind(MissionMessage.PHASE.READY))
	MissionManager.mission_completed.connect(_on_mission_phase.bind(MissionMessage.PHASE.COMPLETED))
	MissionManager.mission_progressed.connect(_on_mission_progressed)
	#TODO Close comms instantly without animation
	#SignalBus.request_comms_popup.connect(close_comms.unbind(2))


func _handle_entering_new_system(system_data:SystemData) -> void:
	if _in_enemy_system(system_data):
			await get_tree().create_timer(3.0).timeout
			open_comms(system_data.faction)


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


func _on_mission_phase(mission: MissionData, phase: MissionMessage.PHASE) -> void:
	_show_message(MissionMessage.get_speaker_faction(mission, phase), MissionMessage.get_message(mission, phase))


func _on_mission_progressed(mission: MissionData, remaining: int) -> void:
	var phase: MissionMessage.PHASE = MissionMessage.PHASE.PROGRESS
	_show_message(MissionMessage.get_speaker_faction(mission, phase), MissionMessage.get_message(mission, phase, remaining), true)


## Hostile-system warning. Mission comms ignore the warnings setting.
func open_comms(system_faction: Utility.FACTION) -> void:
	if disabled: return
	_show_message(system_faction, _get_warning_message(system_faction))


## Queues behind a message already on screen. Progress updates replace each
## other rather than stacking up.
func _show_message(faction: Utility.FACTION, text: String, is_progress: bool = false) -> void:
	if text.is_empty():
		return

	if visible and not _closing:
		if is_progress and _showing_progress and _queue.is_empty():
			comms_message.text = text
			timer.start()
			return
		if is_progress:
			_queue = _queue.filter(func(entry: Dictionary) -> bool: return not entry.progress)
		_queue.append({"faction": faction, "text": text, "progress": is_progress})
		return

	if _closing:
		_queue.append({"faction": faction, "text": text, "progress": is_progress})
		return

	_display(faction, text, is_progress)


func _display(faction: Utility.FACTION, text: String, is_progress: bool) -> void:
	_showing_progress = is_progress
	timer.start()
	match faction:
		Utility.FACTION.ROMULAN:
			$FactionHead.texture = RomulanHeads.pick_random()
		Utility.FACTION.KLINGON:
			$FactionHead.texture = KlingonHeads.pick_random()
		_: # Federation, and neutral contacts until they get their own portraits
			$FactionHead.texture = FederationHeads.pick_random()

	comms_message.text = text
	self.modulate = Color("ffffff")
	self.visible = true


func close_comms() -> void:
	if _closing or not visible:
		return

	# On timeout (timer already stopped), hold the message while a menu such as
	# the starbase screen covers the HUD. The acknowledge button always closes.
	if timer.is_stopped() and Utility.current_menu != Utility.MENUSTATE.NONE:
		timer.start()
		return

	# Stop time in case close is triggered by button
	if !timer.is_stopped():
		timer.stop()

	if close_button:
		close_button.pressed = false
		close_button._update_color()

	_closing = true
	fade_anim.play("fade_out")
	await fade_anim.animation_finished
	self.modulate = Color("ffffff")
	_closing = false

	if not _queue.is_empty():
		var next: Dictionary = _queue.pop_front()
		_display(next.faction, next.text, next.progress)


func _get_warning_message(faction: Utility.FACTION) -> String:
	match faction:
		Utility.FACTION.FEDERATION:
			return WarningMessage.get_federation_warning(Utility.player_name)
		Utility.FACTION.ROMULAN:
			return WarningMessage.get_romulan_warning(Utility.player_name)
		Utility.FACTION.KLINGON:
			return WarningMessage.get_klingon_warning(Utility.player_name)
		_:
			return "ERROR, no faction found in warning_popup.gd"
