extends Control

@onready var close_button: TextButton = $CloseButton
@onready var comms_message: RichTextLabel = $Comms_message
@onready var timer: Timer = $Timer
@onready var fade_anim: AnimationPlayer = $fade_anim

@export var FederationHeads: Array[Texture2D]
@export var RomulanHeads: Array[Texture2D]
@export var KlingonHeads: Array[Texture2D]

var disabled: bool = false

func _ready() -> void:
	self.visible = false
	SignalBus.galaxy_warp_finished.connect(_handle_entering_new_system)
	SignalBus.warningsDisabled.connect(func(check_value): disabled = check_value)
	SignalBus.request_comms_popup.connect(close_comms.unbind(2))


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


func open_comms(system_faction: Utility.FACTION) -> void:
	if disabled: return
	
	timer.start()
	match system_faction:
		Utility.FACTION.FEDERATION:
			$FactionHead.texture = FederationHeads.pick_random()
		Utility.FACTION.ROMULAN:
			$FactionHead.texture = RomulanHeads.pick_random()
		Utility.FACTION.KLINGON:
			$FactionHead.texture = KlingonHeads.pick_random()
	
	update_comms_message(system_faction)
	self.visible = true


func close_comms() -> void:
	# Stop time in case close is triggered by button
	if !timer.is_stopped():
		timer.stop()
	
	if close_button:
		close_button.pressed = false
		close_button._update_color()
	
	fade_anim.play("fade_out")
	await fade_anim.animation_finished
	self.modulate = Color("ffffff")


func update_comms_message(faction: Utility.FACTION) -> void:
	var new_warning:String
	match faction:
		Utility.FACTION.FEDERATION:
			new_warning = WarningMessage.get_federation_warning(Utility.player_name)
		Utility.FACTION.ROMULAN:
			new_warning = WarningMessage.get_romulan_warning(Utility.player_name)
		Utility.FACTION.KLINGON:
			new_warning = WarningMessage.get_klingon_warning(Utility.player_name)
		_:
			new_warning = "ERROR, no faction found in warning_popup.gd"
	comms_message.text = new_warning
