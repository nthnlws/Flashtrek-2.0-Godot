extends TextureRect

@export var showing: bool = true
@export var transition_time:float = 0.8
const HIDDEN_POS:Vector2 = Vector2(0, -51)
const SHOWN_POS:Vector2 = Vector2.ZERO

var tween: Tween
var total_distance: float = 51

@onready var mission_text: RichTextLabel = %MissionText
@onready var fed_score: Label = %FedScore
@onready var klingon_score: Label = %KlingonScore
@onready var rom_score: Label = %RomScore


func _ready() -> void:
	MissionManager.mission_started.connect(_update_mission_text)
	MissionManager.Reputation.reputation_total_changed.connect(_update_faction_score)
	MissionManager.mission_completed.connect(_clear_mission_text.unbind(1))
	SignalBus.factionShipDied.connect(_on_enemy_ship_died)
	
	if showing == false:
		position = HIDDEN_POS
	
	mission_text.text = "Mission:"


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("Tab"):
			if showing:
				showing = false
				tween_menu(HIDDEN_POS)
			else:
				showing = true
				tween_menu(SHOWN_POS)


func _clear_mission_text() -> void:
	mission_text.text = "Mission:"


func _on_enemy_ship_died(enemy:FactionCharacter) -> void:
	var SHIP_VALUE = enemy.reputation_value # Get reputation from ship
	match enemy.faction:
		Utility.FACTION.FEDERATION:
			var old_fed:int = int(fed_score.text)
			var old_klingon:int = int(klingon_score.text)

			var new_fed:int = old_fed - SHIP_VALUE
			var new_klingon:int = old_klingon + (SHIP_VALUE * 0.75)
			fed_score.text = str(new_fed)
			fed_score.get_child(0).trigger_shake(false)
			klingon_score.text = str(new_klingon)
			klingon_score.get_child(0).trigger_shake(true)
		Utility.FACTION.KLINGON:
			var old_klingon:int = int(klingon_score.text)
			var old_rom:int = int(rom_score.text)

			var new_klingon:int = old_klingon - SHIP_VALUE
			var new_rom:int = old_rom + (SHIP_VALUE * 0.75)
			klingon_score.text = str(new_klingon)
			klingon_score.get_child(0).trigger_shake(false)
			rom_score.text = str(new_rom)
			rom_score.get_child(0).trigger_shake(true)
		Utility.FACTION.ROMULAN:
			var old_rom:int = int(rom_score.text)
			var old_fed:int = int(fed_score.text)

			var new_rom:int = old_rom - SHIP_VALUE
			var new_fed:int = old_fed + (SHIP_VALUE * 0.75)
			rom_score.text = str(new_rom)
			rom_score.get_child(0).trigger_shake(false)
			fed_score.text = str(new_fed)
			fed_score.get_child(0).trigger_shake(true)


func _update_mission_text(mission_data:MissionData) -> void:
	var fill_dict:Dictionary[String, String]
	if (mission_data.type == MissionData.MISSION_TYPE.DELIVERY
		or mission_data.type == MissionData.MISSION_TYPE.ANALYZE):
			fill_dict = {
				"target": Utility.UI_yellow + mission_data.target_planet_name + "[/color]",
				"system": mission_data.target_system.system_name,
			}
	else:
		fill_dict = {
				"target": Utility.UI_yellow + mission_data.title + "[/color]",
				"system": mission_data.target_system.system_name,
			}
	
	# Color target system to match faction
	match mission_data.target_system.faction:
		Utility.FACTION.FEDERATION:
			fill_dict.system = Utility.fed_blue + mission_data.target_system.system_name + "[/color]"
		Utility.FACTION.ROMULAN:
			fill_dict.system = Utility.rom_green + mission_data.target_system.system_name + "[/color]"
		Utility.FACTION.KLINGON:
			fill_dict.system = Utility.klin_red + mission_data.target_system.system_name + "[/color]"
		Utility.FACTION.NEUTRAL:
			fill_dict.system = Utility.UI_yellow + mission_data.target_system.system_name + "[/color]"
	
	var template_text: String = "Mission: {target} in {system}"
	var formatted_text: String = template_text.format(fill_dict)
	mission_text.text = formatted_text


func _update_faction_score(faction:Utility.FACTION, score:int) -> void:
	match faction:
		Utility.FACTION.FEDERATION:
			fed_score.text = str(score)
			fed_score.get_child(0).trigger_shake(true if score > 0 else false)
		Utility.FACTION.KLINGON:
			klingon_score.text = str(score)
			klingon_score.get_child(0).trigger_shake(true if score > 0 else false)
		Utility.FACTION.ROMULAN:
			rom_score.text = str(score)
			rom_score.get_child(0).trigger_shake(true if score > 0 else false)


func tween_menu(target_position:Vector2) -> void: # Collapse mission menu
	# Stop running tween
	if is_instance_valid(tween):
		tween.kill()
	
	var distance_to_go:float = abs(position.distance_to(target_position))
	var travel_fraction:float = 0.0
	if total_distance > 0:
		travel_fraction = distance_to_go / total_distance
	var dynamic_duration:float = transition_time * travel_fraction
	
	tween = create_tween()
	tween.tween_property(self, "position", target_position, dynamic_duration)
