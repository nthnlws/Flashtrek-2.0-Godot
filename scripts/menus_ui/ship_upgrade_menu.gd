extends Control

signal menu_closed

@export var CORRIDOR_KLINGON: Texture2D = preload("uid://cabdk1q27chx3")
@export var CORRIDOR_ROMULAN = preload("uid://j3fi53qkphtu")
@export var CORRIDOR_FEDERATION = preload("uid://cxp0gxn468sms")
@export var CORRIDOR_NEUTRAL = preload("uid://d0ps0nwg5gyfd")

@onready var background: TextureRect = $corridor_background

func _ready() -> void:
	SignalBus.player_type_changed.connect(_handle_ship_change)
	SignalBus.playerUpgradeApplied.connect(apply_upgrade)
	MissionManager.Reputation.reputation_total_changed.connect(update_reputation)
	MissionManager.Reputation.player_faction_changed.connect(update_faction_colors)
	
	set_background(LevelManager.galaxy_data.player_ship_type)


func update_faction_colors(new_faction:Utility.FACTION) -> void:
	var faction_icons:Array = get_tree().get_nodes_in_group("faction_label_icon")
	for icon:TextureRect in faction_icons:
		icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if new_faction == Utility.FACTION.FEDERATION:
		%federation_icon.modulate = Color("#3984BE")
	elif new_faction == Utility.FACTION.KLINGON:
		%klingon_icon.modulate = Color("#FF2A2A")
	elif new_faction == Utility.FACTION.ROMULAN:
		%romulan_icon.modulate = Color("#009301")


func update_reputation(faction:Utility.FACTION, new_value:float) -> void:
	var label_text:String = str(roundi(new_value))
	if is_zero_approx(new_value):
		label_text = "0.0"
		return
	
	match faction:
		Utility.FACTION.FEDERATION:
			%federation_rep.text = label_text
			%federation_rep.modulate = Color("009301") if new_value > 0 else Color("f04d40ff")
		Utility.FACTION.KLINGON:
			%klingon_rep.text = label_text
			%klingon_rep.modulate = Color("009301") if new_value > 0 else Color("f04d40ff")
		Utility.FACTION.ROMULAN:
			%romulan_rep.text = label_text
			%romulan_rep.modulate = Color("009301") if new_value > 0 else Color("f04d40ff")
		_:
			print("No faction %s found to update on ship stats screen" % Utility.FACTION.keys()[faction])


func _on_close_menu_button_pressed() -> void:
	self.visible = false
	menu_closed.emit()


func _handle_ship_change(ship_type: Utility.SHIP_TYPES, new_stats: Dictionary) -> void:
	#print("ship type set to %s in upgrade menu" % Utility.SHIP_TYPES.keys()[ship_type])
	set_background(ship_type)
	
	%ship_name.text = "Ship Name: %s" % Utility.SHIP_TYPES.keys()[ship_type].capitalize()
	%faction.text = "Current Faction: %s" % Utility.FACTION.keys()[new_stats.FACTION].capitalize()
	%health_stat.text = "Health: %s" % new_stats.MAX_HP
	%shield_stat.text = "Shield: %s" % new_stats.MAX_SHIELD
	%speed_stat.text = "Max Speed: %s" % new_stats.SPEED
	%agility_stat.text = "Agility: %s" % new_stats.ROTATION_SPEED
	%weapon.text = "Weapon: Torpedo"


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
			%Rotation.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.FIRE_RATE:
			%FireRate.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.HEALTH:
			%Health.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.SHIELD:
			%Shield.upgrade_number += 1
		UpgradePickup.MODULE_TYPES.DAMAGE:
			%Damage.upgrade_number += 1
