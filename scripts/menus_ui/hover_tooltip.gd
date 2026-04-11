extends PanelContainer

@onready var TooltipText: RichTextLabel = $TooltipText
const OFFSET: Vector2 = Vector2(6, 0)

@export var text: String = "Increases fire rate of all weapons by 10%":
	set(new_text):
		text = new_text
		if TooltipText:
			TooltipText.text = new_text
			size = TooltipText.get_minimum_size()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseMotion:
		_update_position(get_global_mouse_position())

func _ready() -> void:
	TooltipText.text = text
	size = TooltipText.get_minimum_size()

func _update_position(mouse_pos: Vector2) -> void:
	var viewport_width: float = get_viewport_rect().size.x
	var tooltip_width: float = size.x

	# Check if right edge would go off screen
	var would_overflow: bool = (mouse_pos.x + OFFSET.x + tooltip_width) > viewport_width

	if would_overflow:
		# Flip to left side of cursor
		global_position = Vector2(mouse_pos.x - OFFSET.x - tooltip_width, mouse_pos.y + OFFSET.y)
	else:
		global_position = Vector2(mouse_pos.x + OFFSET.x, mouse_pos.y + OFFSET.y)
