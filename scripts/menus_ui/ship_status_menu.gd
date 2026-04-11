extends Control
class_name ShipStatusMenu

signal menu_closed

@export var CORRIDOR_KLINGON: Texture2D = preload("uid://cabdk1q27chx3")
@export var CORRIDOR_ROMULAN = preload("uid://j3fi53qkphtu")
@export var CORRIDOR_FEDERATION = preload("uid://cxp0gxn468sms")
@export var CORRIDOR_NEUTRAL = preload("uid://d0ps0nwg5gyfd")
const GREEN_PROGRESS_FILL = preload("uid://cfvn6vh2rs2m")
const RED_PROGRESS_FILL = preload("uid://cypx6ypk7ff2w")

@onready var background: TextureRect = $Background

func _ready() -> void:
	SignalBus.player_type_changed.connect(_handle_ship_change)
	SignalBus.playerUpgradeApplied.connect(apply_upgrade)
	MissionManager.Reputation.reputation_total_changed.connect(update_reputation)
	
	SignalBus.playerHealthChanged.connect(_update_current_health)
	SignalBus.playerMaxHealthChanged.connect(_update_max_health)
	SignalBus.playerMaxShieldChanged.connect(_update_max_shield)
	SignalBus.playerShieldChanged.connect(_update_current_shield)
	SignalBus.playerMaxEnergyChanged.connect(_update_max_energy)
	SignalBus.playerEnergyChanged.connect(_update_current_energy)
	
	set_background(LevelManager.galaxy_data.player_ship_type)
	sync_faction_scores()


func set_background(ship_index: Utility.SHIP_TYPES) -> void:
	var faction = Utility.get_faction_from_ship_type(ship_index)
	match faction:
		Utility.FACTION.FEDERATION:
			background.texture = CORRIDOR_FEDERATION
		Utility.FACTION.ROMULAN:
			background.texture = CORRIDOR_ROMULAN
		Utility.FACTION.KLINGON:
			background.texture = CORRIDOR_KLINGON
		Utility.FACTION.NEUTRAL:
			background.texture = CORRIDOR_NEUTRAL


func apply_upgrade(upgrade_type:UpgradePickup.MODULE_TYPES) -> void:
	match upgrade_type:
		UpgradePickup.MODULE_TYPES.SPEED:
			%Speed.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.ROTATION:
			%Agility.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.FIRE_RATE:
			%FireRate.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.HEALTH:
			%Health.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.SHIELD:
			%Shield.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.DAMAGE:
			%Damage.upgrade_number += 1


func _handle_ship_change(ship_type: Utility.SHIP_TYPES, new_stats: PlayableShipStats) -> void:
	set_background(ship_type)
	_change_ship_sprite(ship_type)

	# Spider Graph — sigmoid-normalised matches progression curve
	var graph: SpiderGraph = %SpiderGraph
	var stat_ranges: Dictionary = new_stats.stat_ranges.get(new_stats.faction, {})

	if stat_ranges.is_empty():
		push_warning("ShipStatusMenu: no max_values found for faction %s" % Utility.FACTION.keys()[new_stats.faction])
	else:
		var graph_dict: Dictionary[String, float] = {
			#"SPEED":   inverse_lerp(stat_ranges["speed"]["min"], stat_ranges["speed"]["max"], new_stats.speed),
			"ARMOR":   Scaling.get_player_stat_scale(inverse_lerp(stat_ranges["max_hp"]["min"], stat_ranges["max_hp"]["max"], new_stats.max_hp)) / Scaling.PLAYER_STAT_MAX,
			"SHIELDS": Scaling.get_player_stat_scale(inverse_lerp(stat_ranges["max_shield"]["min"], stat_ranges["max_shield"]["max"], new_stats.max_shield)) / Scaling.PLAYER_STAT_MAX,
			"DAMAGE":  Scaling.get_player_stat_scale(inverse_lerp(stat_ranges["damage"]["min"], stat_ranges["damage"]["max"], new_stats.damage_mult)) / Scaling.PLAYER_STAT_MAX,
			#"AGILITY": inverse_lerp(stat_ranges["agility"]["min"], stat_ranges["agility"]["max"], new_stats.agility),
			"RANGE":   (new_stats.warp_range / 6.0),
		}
		graph.set_all_values(graph_dict)
	
	%ClassLabel.text = str(Utility.SHIP_TYPES.keys()[ship_type]).capitalize()
	%FactionLabel.text = _format_faction_label(new_stats.faction)
	
	%HealthLabel.text = "%d / %d" % [new_stats.max_hp, new_stats.max_hp]
	%ShieldLabel.text = "%d / %d" % [new_stats.max_shield, new_stats.max_shield]
	%EnergyLabel.text = "%d / %d" % [new_stats.max_energy, new_stats.max_energy]
	
	#TODO %CloakStatus.text
	#TODO Dynamic weapon name
	%WeaponName.text = "TORPEDO"
	%AbilityValue.text = str(Scaling.ARCHETYPE.keys()[new_stats.archetype]).capitalize() if new_stats.archetype else "None"


func _format_faction_label(faction: Utility.FACTION) -> String:
	var base_string: String = "[color=#cc7a00]• [/color]"
	var faction_string: String
	if faction == Utility.FACTION.FEDERATION:
		faction_string = "%sFEDERATION" % Utility.fed_blue
	elif faction == Utility.FACTION.KLINGON:
		faction_string = "%sKLINGON" % Utility.klin_red
	elif faction == Utility.FACTION.ROMULAN:
		faction_string = "%sROMULAN" % Utility.rom_green
	elif faction == Utility.FACTION.NEUTRAL:
		faction_string = "%sNEUTRAL" % Utility.UI_yellow
	
	return base_string + faction_string


func update_reputation(faction:Utility.FACTION, new_value:float) -> void:
	if faction == Utility.FACTION.FEDERATION:
		_set_faction_progress_bar(new_value, %FedReputationBar)
		_set_faction_label(new_value, %FedRepLabel)
	elif faction == Utility.FACTION.KLINGON:
		_set_faction_progress_bar(new_value, %KlingonReputationBar)
		_set_faction_label(new_value, %KlingonRepLabel)
	elif faction == Utility.FACTION.ROMULAN:
		_set_faction_progress_bar(new_value, %RomReputationBar)
		_set_faction_label(new_value, %RomRepLabel)

func _set_faction_progress_bar(new_value:float, progress_bar:ProgressBar) -> void:
	if new_value < 0 and progress_bar.get_theme_stylebox("fill") != RED_PROGRESS_FILL:
		progress_bar.add_theme_stylebox_override("fill", RED_PROGRESS_FILL)
	if new_value > 0 and progress_bar.get_theme_stylebox("fill") != GREEN_PROGRESS_FILL:
		progress_bar.add_theme_stylebox_override("fill", GREEN_PROGRESS_FILL)
	
	progress_bar.value = abs(new_value)

func _set_faction_label(new_value:float, label:Label) -> void:
	# Zero check
	if is_zero_approx(new_value):
		label.text = "0.00"
		label.modulate = Color.WHITE
		return
	
	# Positive reputation
	elif new_value > 0:
		label.modulate = Color("009301")
	# Negative reputation
	elif new_value < 0:
		label.modulate = Color("f04d40ff")
	
	label.text = _format_int_commas(roundi(new_value))


func _format_int_commas(value: int) -> String:
	var negative: bool = value < 0
	var digits: String = str(absi(value))
	var result: String = ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			result += ","
		result += digits[i]
	return ("-" if negative else "") + result


func _on_close_button_pressed() -> void:
	self.visible = false
	menu_closed.emit()


#region Update Player Stats
@onready var health_bar: ProgressBar = %HealthBar
@onready var health_label: Label = %HealthLabel
func _update_current_health(new_value:float) -> void:
	var floored_val:float = max(new_value, 0.0)
	health_bar.value = floored_val
	health_label.text = "%d / %d" % [floored_val, health_bar.max_value]

func _update_max_health(new_value:float) -> void:
	health_bar.max_value = new_value
	health_label.text = "%d / %d" % [health_bar.value, new_value]

@onready var shield_bar: ProgressBar = %ShieldBar
@onready var shield_label: Label = %ShieldLabel
func _update_current_shield(new_value:float) -> void:
	var floored_val:float = max(new_value, 0.0)
	shield_bar.value = floored_val
	shield_label.text = "%d / %d" % [floored_val, shield_bar.max_value]

func _update_max_shield(new_value:float) -> void:
	shield_bar.max_value = new_value
	shield_label.text = "%d / %d" % [shield_bar.value, new_value]

@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_label: Label = %EnergyLabel
func _update_current_energy(new_value:float) -> void:
	var floored_val:float = max(new_value, 0.0)
	energy_bar.value = floored_val
	energy_label.text = "%d / %d" % [floored_val, energy_bar.max_value]

func _update_max_energy(new_value:float) -> void:
	energy_bar.max_value = new_value
	energy_label.text = "%d / %d" % [energy_bar.value, new_value]

func _change_ship_sprite(ship_type:Utility.SHIP_TYPES) -> void:
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[ship_type]
	%ShipSprite.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)

func sync_faction_scores() -> void:
	update_reputation(Utility.FACTION.FEDERATION, MissionManager.Reputation.FederationRep)
	update_reputation(Utility.FACTION.KLINGON, MissionManager.Reputation.KlingonRep)
	update_reputation(Utility.FACTION.ROMULAN, MissionManager.Reputation.RomulanRep)
	
#endregion
