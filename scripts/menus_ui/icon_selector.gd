extends Control
class_name IconSelector

signal icon_selected
signal icon_hovered

@onready var background: ColorRect = %background
@onready var icon: TextureRect = %icon
@onready var gray_out: ColorRect = %gray_out
@onready var lock_symbol: TextureRect = $lock_symbol
@onready var frame: NinePatchRect = $Frame

const DEFAULT_GREY:Color = Color("5d5d5d")
const PRESSED_GREY:Color = Color("929292ff")
var default_frame_color: Color = Color(1.0, 1.0, 1.0)

@export var grayed_out:bool = true
@export var current_icon: Texture2D
@export var can_click: bool = true
@export var can_hover: bool = true
@export var can_highlight: bool = true
var is_hovered:bool = false:
	set(value):
		is_hovered = value
		set_highlighted(value)


func _ready() -> void:
	set_gray_out(grayed_out)
	set_icon(current_icon)


func _on_hovered() -> void:
	if !can_hover: return
	background.color = PRESSED_GREY
	is_hovered = true
	icon_hovered.emit()


func _on_mouse_exited() -> void:
	background.color = DEFAULT_GREY
	is_hovered = false

func set_highlighted(highlight_active: bool) -> void:
	if !can_highlight: return
	frame.self_modulate = Color("ffe070") if highlight_active else default_frame_color


func set_icon(texture:Texture2D) -> void:
	icon.texture = texture


func set_gray_out(state:bool) -> void:
	grayed_out = state
	gray_out.visible = state
	lock_symbol.visible = state


func _on_button_down() -> void:
	if !can_click: return
	icon.scale = Vector2(0.8, 0.8)
	if !grayed_out:
		icon_selected.emit()


func _on_button_up() -> void:
	icon.scale = Vector2(0.85, 0.85)
