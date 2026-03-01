extends TextureButton
class_name IconSelector

signal icon_selected
signal icon_hovered

@onready var background: ColorRect = $background
@onready var icon: TextureRect = %icon
@onready var gray_out: ColorRect = $gray_out
@onready var lock_symbol: TextureRect = $lock_symbol

const DEFAULT_GREY:Color = Color("5d5d5d")
const PRESSED_GREY:Color = Color("707070")

@export var grayed_out:bool = true
@export var current_icon: Texture2D


func _ready() -> void:
	set_gray_out(grayed_out)
	set_icon(current_icon)


func _on_hovered() -> void:
	background.color = PRESSED_GREY
	icon_hovered.emit()


func _on_mouse_exited() -> void:
	background.color = DEFAULT_GREY


func set_icon(texture:Texture2D) -> void:
	icon.texture = texture


func set_gray_out(state:bool) -> void:
	grayed_out = state
	gray_out.visible = state
	lock_symbol.visible = state


func _on_button_down() -> void:
	icon.scale = Vector2(0.8, 0.8)
	if !grayed_out:
		icon_selected.emit()


func _on_button_up() -> void:
	icon.scale = Vector2(0.85, 0.85)
