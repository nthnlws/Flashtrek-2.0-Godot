extends Control
class_name ShipCardButton

signal hovered(button: ShipCardButton)
signal unhovered(button: ShipCardButton)
signal clicked(button: ShipCardButton)
signal released(button: ShipCardButton)

@export var can_click: bool = true
@export var can_hover: bool = true
@export var grayed_out: bool = true

var is_hovered:bool = false
var ship_info: ShipState

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
	
	if !ship_info: return
	set_unlock_cost(ship_info.unlock_cost)
	set_gray_out(grayed_out)
	_create_unique_atlas()
	set_ship_type(ship_info)


var current_state: STATE = STATE.EXITED
func _update_sync_state(new_state: STATE):
	if new_state == STATE.PRESSED:
		left_panel.add_theme_stylebox_override("panel", LEFT_PRESSED)
		right_panel.add_theme_stylebox_override("panel", RIGHT_PRESSED)
		current_state = new_state
		if !grayed_out:
			clicked.emit(ship_info.unlock_price)
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


func set_ship_type(ship_info: ShipState) -> void:
	var base_info: BaseShipInfo = Utility.get_ship_stats(ship_info.ship_type)
	ship_sprite.texture.region = Rect2(base_info.sprite_coords, Vector2(48, 48))
	class_name_label.text = str(base_info.ship_type)


func set_gray_out(new_state:bool) -> void:
	grayed_out = new_state
	lock_texture.visible = new_state
	$GrayoutPanel.visible = new_state


func set_unlock_cost(unlock_price:int, is_unlocked:bool = false) -> void:
	var text_color: String = Utility.UI_cargo_green if is_unlocked else Utility.damage_red
	if unlock_price > 0:
		rep_unlock_status.text = text_color + "Required Rep: " + Utility.format_number(unlock_price)
	else:
		rep_unlock_status.text = Utility.UI_cargo_green + "Unlocked"


func set_copper_state(is_copper:bool) -> void:
	$CopperContainer.visible = is_copper

func update_color(new_color: Color) -> void:
	self.modulate = new_color


static func create_ship_button(scaled_info: ShipState) -> ShipCardButton:
	var button: ShipCardButton = load("uid://qu0xx1uo0wsd").instantiate()
	button.ship_info = scaled_info
	if scaled_info.ship_type == Utility.starting_ship:
		button.grayed_out   = false
	return button
