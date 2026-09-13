extends Panel

@onready var text_button: TextButton = $TextButton


func _on_button_hovered() -> void:
	text_button.scale = Vector2(1.5, 1.5)


func _on_text_button_unhovered() -> void:
	text_button.scale = Vector2.ONE
