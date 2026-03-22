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
	if !can_hover: return
	background.color = PRESSED_GREY
	is_hovered = true
	icon_hovered.emit(self)


func _create_unique_atlas() -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.filter_clip = true
	atlas_texture.region = Rect2(0.0, 0.0, 48.0, 48.0)
	icon.texture = atlas_texture


func set_faction(faction: Utility.FACTION) -> void:
	match faction:
		Utility.FACTION.FEDERATION:
			frame.self_modulate =	Color(0.457, 0.562, 0.869, 1.0)
			default_frame_color =	Color(0.457, 0.562, 0.869, 1.0)
		Utility.FACTION.ROMULAN:
			frame.self_modulate =	Color(0.302, 0.522, 0.27, 1.0)
			default_frame_color =	Color(0.302, 0.522, 0.27, 1.0)
		Utility.FACTION.KLINGON:
			frame.self_modulate =	Color(0.743, 0.32, 0.321, 1.0)
			default_frame_color =	Color(0.743, 0.32, 0.321, 1.0)
		Utility.FACTION.NEUTRAL:
			frame.self_modulate =	Color(1.0, 1.0, 1.0)
			default_frame_color =	Color(1.0, 1.0, 1.0)


func set_ship_type(type: Utility.SHIP_TYPES) -> void:
	var ship_data:Dictionary = Utility.SHIP_DATA[type]
	icon.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)


func _on_button_down() -> void:
	if !can_click:return
	icon.scale = Vector2(0.8, 0.8)
	if !grayed_out:
		icon_selected.emit(current_ship_type)
