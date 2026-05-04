extends Control
class_name ShipCardButton

signal hovered(button: ShipCardButton)
signal unhovered(button: ShipCardButton)
signal clicked(button: ShipCardButton)
signal released(button: ShipCardButton)

@export var current_ship_type:Utility.SHIP_TYPES = 0 as Utility.SHIP_TYPES
@export var ship_faction:Utility.FACTION = Utility.FACTION.NEUTRAL
@export var unlock_price: int = 0

@export var can_click: bool = true
@export var can_hover: bool = true
@export var grayed_out: bool = true

var is_hovered:bool = false
@onready var ship_sprite: TextureRect = %ShipSprite
@onready var lock_texture: TextureRect = %LockTexture
@onready var class_name_label: RichTextLabel = %ClassNameLabel
@onready var rep_unlock_status: RichTextLabel = %RepUnlockStatus
@onready var left_panel: Panel = %LeftPanel
@onready var right_panel: Panel = %RightPanel
@onready var button_detector: PolygonMouseDetector = $ButtonDetector

const LEFT_HOVER = preload("uid://1g5c3ff4rhyp")
const LEFT_NORMAL = preload("uid://gwxko7746pea")
const LEFT_PRESSED = preload("uid://ck76ige0oxi3c")
const RIGHT_HOVER = preload("uid://cwojku7c1jhsn")
const RIGHT_NORMAL = preload("uid://cp1bhkwan3qaf")
const RIGHT_PRESSED = preload("uid://dwoovfbhpixyq")

enum STATE { ENTERED, EXITED, PRESSED, RELEASED }

func _ready() -> void:
	button_detector.mouse_entered.connect(_update_sync_state.bind(STATE.ENTERED))
	button_detector.mouse_exited.connect(_update_sync_state.bind(STATE.EXITED))
	button_detector.pressed.connect(_update_sync_state.bind(STATE.PRESSED))
	button_detector.released.connect(_update_sync_state.bind(STATE.RELEASED))
	
	set_unlock_cost(unlock_price)
	set_gray_out(grayed_out)
	_create_unique_atlas()
	set_ship_type(current_ship_type)

var current_state: STATE = STATE.EXITED
func _update_sync_state(new_state: STATE):
	if new_state == STATE.PRESSED:
		left_panel.add_theme_stylebox_override("panel", LEFT_PRESSED)
		right_panel.add_theme_stylebox_override("panel", RIGHT_PRESSED)
		current_state = new_state
		if !grayed_out:
			clicked.emit(current_ship_type)
	elif new_state == STATE.ENTERED:
		left_panel.add_theme_stylebox_override("panel", LEFT_HOVER)
		right_panel.add_theme_stylebox_override("panel", RIGHT_HOVER)
		current_state = new_state
		if !grayed_out:
			hovered.emit(self)
			ship_sprite.scale = Vector2(1.1, 1.1)
	elif new_state == STATE.EXITED:
		left_panel.add_theme_stylebox_override("panel", LEFT_NORMAL)
		right_panel.add_theme_stylebox_override("panel", RIGHT_NORMAL)
		ship_sprite.scale = Vector2.ONE
		current_state = new_state
	elif new_state == STATE.RELEASED:
		if current_state != STATE.EXITED:
			left_panel.add_theme_stylebox_override("panel", LEFT_NORMAL)
			right_panel.add_theme_stylebox_override("panel", RIGHT_NORMAL)
			current_state = new_state
			if !grayed_out:
				released.emit(self)
		else:
			current_state = STATE.EXITED


func _create_unique_atlas() -> void:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.filter_clip = true
	atlas_texture.region = Rect2(0.0, 0.0, 48.0, 48.0)
	ship_sprite.texture = atlas_texture


func set_ship_type(type: Utility.SHIP_TYPES) -> void:
	var ship_data:Dictionary = Utility.SHIP_DATA[type]
	ship_sprite.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
	class_name_label.text = str(Utility.SHIP_TYPES.keys()[type]).capitalize()


func set_gray_out(new_state:bool) -> void:
	grayed_out = new_state
	lock_texture.visible = new_state
	$GrayoutPanel.visible = new_state


func set_unlock_cost(unlock_cost:int, is_unlocked:bool = false) -> void:
	var text_color: String = Utility.UI_cargo_green if is_unlocked else Utility.damage_red
	if unlock_price > 0:
		rep_unlock_status.text = text_color + "Required Rep: " + Utility.format_number(unlock_cost)
	else:
		rep_unlock_status.text = Utility.UI_cargo_green + "Unlocked"


func set_copper_state(is_copper:bool) -> void:
	$CopperContainer.visible = is_copper

func update_color(new_color: Color) -> void:
	self.modulate = new_color
