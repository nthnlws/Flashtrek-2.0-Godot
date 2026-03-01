extends IconSelector
class_name ShipSelector


@export var current_ship_type:Utility.SHIP_TYPES = 0 as Utility.SHIP_TYPES
@export var ship_faction:Utility.FACTION = Utility.FACTION.NEUTRAL
@export var unlock_price: int = 0

func _ready() -> void:
	_create_unique_atlas()
	
	set_gray_out(grayed_out)
	set_ship_type(current_ship_type)
	set_faction(ship_faction)


func _on_hovered() -> void:
	background.color = PRESSED_GREY
	icon_hovered.emit(self)


func _create_unique_atlas() -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.filter_clip = true
	atlas_texture.region = Rect2(0.0, 0.0, 48.0, 48.0)
	icon.texture = atlas_texture


func set_faction(faction) -> void:
	match faction:
		"Federation":
			self_modulate = Color(0.393, 0.501, 0.831)
		"Romulan":
			self_modulate = Color(0.248, 0.436, 0.22)
		"Klingon":
			self_modulate = Color(0.631, 0.255, 0.258)
		"Neutral":
			self_modulate = Color(1.0, 1.0, 1.0)


func set_ship_type(type: Utility.SHIP_TYPES) -> void:
	#print(Utility.SHIP_TYPES.keys()[i] + " " + str(i))
	var ship_data:Dictionary = Utility.SHIP_DATA[type]
	icon.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)


func _on_button_down() -> void:
	icon.scale = Vector2(0.8, 0.8)
	if !grayed_out:
		SignalBus.player_type_changed.emit(current_ship_type)
		icon_selected.emit(current_ship_type)
