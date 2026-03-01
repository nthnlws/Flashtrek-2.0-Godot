extends Control
 
@onready var ambience: AudioStreamPlayer = $ambience
@onready var frames: Array[ShipSelector] = []

var FederationRep: float = 0.0
var KlingonRep: float = 0.0
var RomulanRep: float = 0.0
var NeutralRep: float = 0.0

signal menu_closed

@export var federation_unlocks: Array[Utility.SHIP_TYPES]
@export var klingon_unlocks: Array[Utility.SHIP_TYPES]
@export var romulan_unlocks: Array[Utility.SHIP_TYPES]
@export var neutral_unlocks: Array[Utility.SHIP_TYPES]

const SHIP_SELECTOR = preload("uid://djjxdvhjd147f")


func _ready() -> void:
	MissionManager.Reputation.reputation_total_changed.connect(_update_faction_reputations)
	
	update_selection_grid()
	#TODO Connect signals in FRAME CREATION
	#for frame: ShipSelector in frames:
		#frame.icon_selected.connect(_on_close_menu_button_pressed)
		#frame.icon_hovered.connect(update_ship_stats)


func update_selection_grid() -> void:
	# Clear old frames
	var old_frames: Array[Node] = get_tree().get_nodes_in_group("ship_selection_frame")
	for frame: Node in old_frames:
		frame.free()

	# Create new frames
	for i: int in range(federation_unlocks.size()):
		var ship_type: Utility.SHIP_TYPES = federation_unlocks[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, federation_unlocks.size())
		var frame: ShipSelector = create_frame(ship_type, Utility.FACTION.FEDERATION, unlock_cost)
		%FederationGrid.add_child(frame)
	for i: int in range(klingon_unlocks.size()):
		var ship_type: Utility.SHIP_TYPES = klingon_unlocks[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, klingon_unlocks.size())
		var frame: ShipSelector = create_frame(ship_type, Utility.FACTION.KLINGON, unlock_cost)
		%KlingonGrid.add_child(frame)
	for i: int in range(romulan_unlocks.size()):
		var ship_type: Utility.SHIP_TYPES = romulan_unlocks[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, romulan_unlocks.size())
		var frame: ShipSelector = create_frame(ship_type, Utility.FACTION.ROMULAN, unlock_cost)
		%RomulanGrid.add_child(frame)
	for i: int in range(neutral_unlocks.size()):
		var ship_type: Utility.SHIP_TYPES = neutral_unlocks[i]
		var unlock_cost: int = Scaling.get_unlock_cost_scale(i, neutral_unlocks.size())
		var frame: ShipSelector = create_frame(ship_type, Utility.FACTION.NEUTRAL, unlock_cost)
		%NeutralGrid.add_child(frame)


func create_frame(ship_type: Utility.SHIP_TYPES, faction: Utility.FACTION, unlock_cost: int) -> ShipSelector:
	var frame: ShipSelector = SHIP_SELECTOR.instantiate()
	frame.current_ship_type = ship_type
	frame.ship_faction = faction
	frame.unlock_price = unlock_cost
	if ship_type == Utility.starting_ship:
		frame.unlock_price = 0
		frame.grayed_out = false
	frame.icon_selected.connect(_on_close_menu_button_pressed)
	frame.icon_hovered.connect(update_ship_stats)
	return frame

func _update_faction_reputations(faction: Utility.FACTION, new_score: float) -> void:
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
			push_error("Trying to update unknown faction in ship selection menu")


func _update_ship_unlocks(faction: Utility.FACTION, _new_score: float) -> void:
	#print("new rep: %s for faction %s" % [_new_score, faction])
	match faction:
		Utility.FACTION.FEDERATION:
			for frame: ShipSelector in frames:
				if frame.ship_faction == Utility.FACTION.FEDERATION and federation_unlocks.has(frame.current_ship_type):
					if FederationRep >= federation_unlocks[frame.current_ship_type]:
						#print('ungreying fed frame: %s' % frame.name)
						frame.set_gray_out(false)
					else:
						#print('greying fed frame: %s' % frame.name)
						frame.set_gray_out(true)
		Utility.FACTION.KLINGON:
			for frame: ShipSelector in frames:
				if frame.ship_faction == Utility.FACTION.KLINGON and klingon_unlocks.has(frame.current_ship_type):
					if KlingonRep >= klingon_unlocks[frame.current_ship_type]:
						frame.set_gray_out(false)
					else:
						frame.set_gray_out(true)
		Utility.FACTION.ROMULAN:
			for frame: ShipSelector in frames:
				if frame.ship_faction == Utility.FACTION.ROMULAN and romulan_unlocks.has(frame.current_ship_type):
					if RomulanRep >= romulan_unlocks[frame.current_ship_type]:
						frame.set_gray_out(false)
					else:
						frame.set_gray_out(true)
		Utility.FACTION.NEUTRAL:
			for frame: ShipSelector in frames:
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
		%price_banner.text = "Reputation Required: "

func start_ambience() -> void:
	ambience.volume_db = -25
	ambience.play()
	var tween: Tween = create_tween()
	tween.tween_property(ambience, "volume_db", -20, 4.0)


func _handle_menu_closed(type: Utility.SHIP_TYPES) -> void:
	SignalBus.player_type_changed.emit(type)
	self.visible = false
	menu_closed.emit()
	ambience.stop()
	clear_stats()


func update_ship_stats(selected_ship: ShipSelector) -> void:
	var faction: Utility.FACTION = selected_ship.ship_faction
	var ship_stats: Dictionary = Utility.SHIP_STATS[selected_ship.current_ship_type]
	

	%ship_name.text = "Ship Name: " + Utility.UI_ship_lime + ship_stats.SHIP_NAME.replace("_", " ")
	%health_stat.text = "Health: %s" % ship_stats.MAX_HP
	%shield_stat.text = "Shield: %s" % ship_stats.MAX_SHIELD
	%weapon.text = "Default Weapon: Torpedo"
	%speed_stat.text = "Max Speed: %s" % ship_stats.PLAYER_SPEED_OVERRIDE
	%maneuver_stat.text = "Maneuverability: %s" % ship_stats.PLAYER_ROTATION_OVERRIDE
	
	match faction:
		Utility.FACTION.FEDERATION:
			%faction.text = "Faction: " + Utility.fed_blue + str(Utility.FACTION.keys()[faction]).to_pascal_case()
		Utility.FACTION.KLINGON:
			%faction.text = "Faction: " + Utility.klin_red + str(Utility.FACTION.keys()[faction]).to_pascal_case()
		Utility.FACTION.ROMULAN:
			%faction.text = "Faction: " + Utility.rom_green + str(Utility.FACTION.keys()[faction]).to_pascal_case()
		Utility.FACTION.NEUTRAL:
			%faction.text = "Faction: " + Utility.neut_cyan + str(Utility.FACTION.keys()[faction]).to_pascal_case()
		
	var req_rep: int = selected_ship.unlock_price
	var my_rep: float = 0.0
	if faction == Utility.FACTION.FEDERATION: my_rep = FederationRep
	elif faction == Utility.FACTION.KLINGON: my_rep = KlingonRep
	elif faction == Utility.FACTION.ROMULAN: my_rep = RomulanRep
	elif faction == Utility.FACTION.NEUTRAL: my_rep = NeutralRep
			
	if req_rep == 0: # Default unlock ship
		%price_banner.text = "Unlocked: %sDefault" % Utility.UI_cargo_green
	else:
		if my_rep >= req_rep:
			%price_banner.text = "Reputation Required: %s%s" % [Utility.UI_cargo_green, req_rep]
		else:
			%price_banner.text = "Reputation Required: %s%s" % [Utility.damage_red, req_rep]

func _on_close_menu_button_pressed() -> void:
	self.visible = false
	menu_closed.emit()
