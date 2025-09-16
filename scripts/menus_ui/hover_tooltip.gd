extends PanelContainer


@onready var TooltipText: RichTextLabel = $TooltipText
const OFFSET: Vector2 = Vector2(6, 0)

@export var text:String = "Increases fire rate of all weapons by 10%":
	set(new_text):
		text = new_text
		if TooltipText:
			TooltipText.text = new_text
			size = TooltipText.get_minimum_size()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + OFFSET

func _ready() -> void:
	TooltipText.text = text
	size = TooltipText.get_minimum_size()
