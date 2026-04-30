extends Label
class_name HighlightLabel

@export var default_text_color:Color = Color.WHITE
@export var highlight_text_color:Color = Color("d4d477")


func _ready() -> void:
	self.mouse_entered.connect(toggle_highlight.bind(true))
	self.mouse_exited.connect(toggle_highlight.bind(false))


func toggle_highlight(highlighted:bool) -> void:
	if highlighted:
		if label_settings:
			label_settings.font_color = highlight_text_color
		else:
			self.add_theme_color_override("font_color", highlight_text_color)
	else:
		if label_settings:
			label_settings.font_color = default_text_color
		else:
			self.add_theme_color_override("font_color", default_text_color)
