extends TextureButton
class_name ShipSelector

signal ship_selected
signal ship_hovered

@onready var background: ColorRect = $background
@onready var ship_sprite: TextureRect = $background/ship_sprite
@onready var gray_out: ColorRect = $gray_out

const DEFAULT_GREY:Color = Color("5d5d5d")
const PRESSED_GREY:Color = Color("707070")

@export var current_ship_type:Utility.SHIP_TYPES = 0
@export var grayed_out:bool = true

@export var ship_faction:Utility.FACTION = Utility.FACTION.NEUTRAL

func _ready() -> void:
	_create_unique_atlas()
	
	set_gray_out(grayed_out)
	set_ship_type(current_ship_type)
	set_faction(ship_faction)


func _on_hovered() -> void:
	background.color = PRESSED_GREY
	ship_hovered.emit(current_ship_type)


func _on_mouse_exited() -> void:
	background.color = DEFAULT_GREY


func _create_unique_atlas() -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.filter_clip = true
	ship_sprite.texture = atlas_texture


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


func set_ship_type(i: Utility.SHIP_TYPES) -> void:
	#print(Utility.SHIP_TYPES.keys()[i] + " " + str(i))
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[i]
	ship_sprite.texture.region =  Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
	


func set_gray_out(state:bool) -> void:
	grayed_out = state
	match grayed_out:
		true:
			gray_out.color = Color("707070c0")
		false:
			gray_out.color = Color("70707000")


func _on_button_down() -> void:
	ship_sprite.scale = Vector2(0.8, 0.8)
	if !grayed_out:
		SignalBus.player_type_changed.emit(current_ship_type)
		ship_selected.emit()


func _on_button_up() -> void:
	ship_sprite.scale = Vector2(0.85, 0.85)
