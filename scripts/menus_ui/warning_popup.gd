extends Control

@onready var close_button: TextButton = $CloseButton
@onready var comms_message: RichTextLabel = $Comms_message

@export var FederationHeads: Array[Texture2D]
@export var RomulanHeads: Array[Texture2D]
@export var KlingonHeads: Array[Texture2D]

func _ready() -> void:
	self.visible = false
	SignalBus.galaxy_warp_finished.connect(_handle_entering_new_system)


func _handle_entering_new_system(system_data:SystemData) -> void:
	if _in_enemy_system(system_data):
			await get_tree().create_timer(3.0).timeout
			open_comms()


func _in_enemy_system(system_data:SystemData):
	if (system_data.faction != LevelManager.player.faction
		and LevelManager.player.faction != Utility.FACTION.NEUTRAL
		and LevelManager.current_system_data.system_name != LevelManager.target_system_data.system_name
		and LevelManager.current_system_data.faction != Utility.FACTION.NEUTRAL):
			return true
	else: return false


func open_comms() -> void:
	var current_faction:Utility.FACTION = LevelManager.current_system_data.faction
	match current_faction:
		Utility.FACTION.FEDERATION:
			$FactionHead.texture = FederationHeads.pick_random()
		Utility.FACTION.ROMULAN:
			$FactionHead.texture = RomulanHeads.pick_random()
		Utility.FACTION.KLINGON:
			$FactionHead.texture = KlingonHeads.pick_random()
	
	update_comms_message(current_faction)
	self.visible = true


func close_comms() -> void:
	visible = false
	if close_button:
		close_button.pressed = false
		close_button._update_color()


func _on_close_ui_pressed() -> void:
	AudioManager.play_UI_click_sound()
	close_comms()


func _on_open_comms_pressed() -> void:
	open_comms()


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
