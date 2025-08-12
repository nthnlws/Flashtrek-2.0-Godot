extends Control
 
@onready var ambience:AudioStreamPlayer = $ambience
@onready var warp_stat: RichTextLabel = %warp_stat
@onready var frames:Array[Node] = get_tree().get_nodes_in_group("selection_frame")

var FederationRep:float = 0.0
var KlingonRep:float = 0.0
var RomulanRep:float = 0.0
var NeutralRep:float = 0.0

signal menu_closed

var federation_unlocks:Dictionary = {
	Utility.SHIP_TYPES.Maquis_Raider: 1000,
	Utility.SHIP_TYPES.Defiant_Class: 3000,
	Utility.SHIP_TYPES.Pathfinder_Class: 4000,
	Utility.SHIP_TYPES.Cardenas_Class: 5000,
	Utility.SHIP_TYPES.California_Class: 6000,
	Utility.SHIP_TYPES.Constitution_II_Class: 8000,
}

var klingon_unlocks:Dictionary = {
	Utility.SHIP_TYPES.Brel_Class: 2000,
	Utility.SHIP_TYPES.D5_Class: 5000,
	Utility.SHIP_TYPES.chargh_Class: 8000,
}

var romulan_unlocks:Dictionary = {
	Utility.SHIP_TYPES.Dhailkhina_Class: 40000,
	Utility.SHIP_TYPES.Dderidex_Class: 8000,
	Utility.SHIP_TYPES.Mogai_Class: 10000,
}

var neutral_unlocks:Dictionary = {
	Utility.SHIP_TYPES.La_Sirena: 0,
	Utility.SHIP_TYPES.Tellarite_Cruiser: 2000,
	Utility.SHIP_TYPES.Galor_Class: 3000,
	Utility.SHIP_TYPES.DKora_Marauder: 4000,
	Utility.SHIP_TYPES.Risian_Corvette: 6000,
	Utility.SHIP_TYPES.Monaveen: 10000,
}

func _ready() -> void:
	_connect_signals()


func _connect_signals() -> void:
	SignalBus.reputationChanged.connect(_update_faction_reputations)
	
	for frame:ShipSelector in frames:
		frame.ship_selected.connect(_on_close_menu_button_pressed)
		frame.ship_hovered.connect(update_ship_stats)


func _update_faction_reputations(faction:Utility.FACTION, new_score:float) -> void:
	match faction:
		Utility.FACTION.FEDERATION:
			FederationRep = new_score
			_update_ship_unlocks(Utility.FACTION.FEDERATION, FederationRep)
		Utility.FACTION.KLINGON:
			KlingonRep = new_score
			_update_ship_unlocks(Utility.FACTION.KLINGON, KlingonRep)
		Utility.FACTION.ROMULAN:
			RomulanRep = new_score
			_update_ship_unlocks(Utility.FACTION.ROMULAN, RomulanRep)
		Utility.FACTION.NEUTRAL:
			NeutralRep = new_score
			_update_ship_unlocks(Utility.FACTION.NEUTRAL, NeutralRep)
		_:
			push_error("Unknown faction")


func _update_ship_unlocks(faction:Utility.FACTION, new_score:float) -> void:
	#print("new rep: %s for faction %s" % [new_score, faction])
	match faction:
		Utility.FACTION.FEDERATION:
			for frame:ShipSelector in frames:
				if frame.ship_faction == Utility.FACTION.FEDERATION and federation_unlocks.has(frame.current_ship_type):
					if FederationRep >= federation_unlocks[frame.current_ship_type]:
						#print('ungreying fed frame: %s' % frame.name)
						frame.set_gray_out(false)
					else:
						#print('greying fed frame: %s' % frame.name)
						frame.set_gray_out(true)
		Utility.FACTION.KLINGON:
			for frame:ShipSelector in frames:
				if frame.ship_faction == Utility.FACTION.KLINGON and klingon_unlocks.has(frame.current_ship_type):
					if KlingonRep >= klingon_unlocks[frame.current_ship_type]:
						frame.set_gray_out(false)
					else:
						frame.set_gray_out(true)
		Utility.FACTION.ROMULAN:
			for frame:ShipSelector in frames:
				if frame.ship_faction == Utility.FACTION.ROMULAN and romulan_unlocks.has(frame.current_ship_type):
					if RomulanRep >= romulan_unlocks[frame.current_ship_type]:
						frame.set_gray_out(false)
					else:
						frame.set_gray_out(true)
		Utility.FACTION.NEUTRAL:
			for frame:ShipSelector in frames:
				if frame.ship_faction == Utility.FACTION.NEUTRAL and neutral_unlocks.has(frame.current_ship_type):
					if NeutralRep >= neutral_unlocks[frame.current_ship_type]:
						frame.set_gray_out(false)
					else:
						frame.set_gray_out(true)


func clear_stats() -> void:
		%ship_name.text = "Ship Name: "
		%faction.text = "Faction: "
		%health_stat.text = "Health: "
		%shield_stat.text = "Shield: "
		%weapon.text = "Default Weapon: "
		%speed_stat.text = "Max Speed: "
		%maneuver_stat.text = "Maneuverability: "
		warp_stat.text = "Warp Range: "


func start_ambience() -> void:
	ambience.volume_db = -25
	ambience.play()
	var tween: Tween = create_tween()
	tween.tween_property(ambience, "volume_db", -20, 4.0)


func _handle_menu_closed(type:Utility.SHIP_TYPES) -> void:
	SignalBus.player_type_changed.emit(type)
	self.visible = false
	menu_closed.emit()
	ambience.stop()
	clear_stats()


func update_ship_stats(ship:Utility.SHIP_TYPES) -> void:
	var ship_data:Dictionary = Utility.PLAYER_SHIP_STATS.values()[ship]
	var faction: Utility.FACTION = Utility.SHIP_DATA.values()[ship].FACTION

	%ship_name.text = "Ship Name: " + Utility.UI_ship_lime + ship_data.SHIP_NAME.replace("_", " ")
	%health_stat.text = "Health: %s" % ship_data.MAX_HP
	%shield_stat.text = "Shield: %s" % ship_data.MAX_SHIELD
	%weapon.text = "Default Weapon: Torpedo"
	%speed_stat.text = "Max Speed: %s" % ship_data.SPEED
	%maneuver_stat.text = "Maneuverability: %s" % ship_data.ROTATION_SPEED
	
	match faction:
		Utility.FACTION.FEDERATION:
			%faction.text = "Faction: " + Utility.fed_blue + str(Utility.FACTION.keys()[Utility.FACTION.FEDERATION]).to_pascal_case()
		Utility.FACTION.KLINGON:
			%faction.text = "Faction: " + Utility.klin_red + str(Utility.FACTION.keys()[Utility.FACTION.KLINGON]).to_pascal_case()
		Utility.FACTION.ROMULAN:
			%faction.text = "Faction: " + Utility.rom_green + str(Utility.FACTION.keys()[Utility.FACTION.ROMULAN]).to_pascal_case()
		Utility.FACTION.NEUTRAL:
			%faction.text = "Faction: " + Utility.neut_cyan + str(Utility.FACTION.keys()[Utility.FACTION.NEUTRAL]).to_pascal_case()
	warp_stat.text = "Warp Range: " + str(ship_data.WARP_RANGE)


func _on_close_menu_button_pressed() -> void:
	self.visible = false
	menu_closed.emit()
