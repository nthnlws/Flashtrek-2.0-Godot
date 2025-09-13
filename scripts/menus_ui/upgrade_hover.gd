extends TextureButton
class_name UpgradeHover

signal icon_hovered
enum Type { DAMAGE, FIRE_RATE, HEALTH, ROTATION, SHIELD, SPEED }

@onready var background: ColorRect = $background
@onready var icon: TextureRect = $background/icon
@onready var gray_out: ColorRect = $gray_out
@onready var lock_symbol: TextureRect = $lock_symbol
@onready var count: RichTextLabel = $UpgradeCount
@onready var tooltip: PanelContainer = $background/HoverTooltip

const DEFAULT_GREY:Color = Color("5d5d5d")
const PRESSED_GREY:Color = Color("707070")
var upgrade_number:int = 0:
	set(new_count):
		upgrade_number = new_count
		count.text = str(new_count)
		if new_count > 0 and count.visible == false:
			count.visible = true
			set_gray_out(false)

@export var current_icon:Type = Type.DAMAGE
@export var upgrade_icons:Dictionary[Type, Texture2D]
@export var grayed_out:bool = true


func _ready() -> void:
	set_gray_out(grayed_out)
	set_icon(current_icon)


func _on_hovered() -> void:
	background.color = PRESSED_GREY
	tooltip.visible = true
	icon_hovered.emit()


func _on_mouse_exited() -> void:
	tooltip.visible = false
	background.color = DEFAULT_GREY


func set_icon(new_texture:Type) -> void:
	icon.texture = upgrade_icons[new_texture]
	match new_texture:
		Type.DAMAGE:
			tooltip.text = "Increases damage dealt by your ship's weapons by 10%"
		Type.FIRE_RATE:
			tooltip.text = "Increases your ship's weapon fire rate by 10%"
		Type.HEALTH:
			tooltip.text = "Increases your ship's max health by 10%"
		Type.ROTATION:
			tooltip.text = "Increases your ship's rotation speed by 10%"
		Type.SHIELD:
			tooltip.text = "Increases your ship's shield capacity by 10%"
		Type.SPEED:
			tooltip.text = "Increases your ship's max speed by 10%"


func set_gray_out(state:bool) -> void:
	grayed_out = state
	gray_out.visible = state
	lock_symbol.visible = state
