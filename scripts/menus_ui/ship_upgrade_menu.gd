extends Control

signal menu_closed

const CORRIDOR_KLINGON_EDITED = preload("res://assets/textures/UI/ship_upgrade_menu/corridor_klingon_edited.png")
const CORRIDOR_ROMULAN_EDITED = preload("res://assets/textures/UI/ship_upgrade_menu/corridor_romulan_edited.png")
const CORRIDOR_FEDERATION_EDITED = preload("res://assets/textures/UI/ship_upgrade_menu/corridor_federation_edited.png")
const CORRIDOR_NEUTRAL_EDITED = preload("res://assets/textures/UI/ship_upgrade_menu/corridor_neutral_edited.png")
const SHIP_DATA = preload("res://assets/data/ShipData.json")

@onready var background: TextureRect = $corridor_background

func _ready() -> void:
	SignalBus.player_type_changed.connect(set_background)
	set_background(Utility.starting_ship)


func _on_close_menu_button_pressed() -> void:
	self.visible = false
	menu_closed.emit()


func set_background(ship_index: Utility.SHIP_TYPES) -> void:
	var faction = Utility.get_faction_from_ship(ship_index)
	match faction:
		Utility.FACTION.FEDERATION:
			background.texture = CORRIDOR_FEDERATION_EDITED
		Utility.FACTION.ROMULAN:
			background.texture = CORRIDOR_ROMULAN_EDITED
		Utility.FACTION.KLINGON:
			background.texture = CORRIDOR_KLINGON_EDITED
		Utility.FACTION.NEUTRAL:
			background.texture = CORRIDOR_NEUTRAL_EDITED
