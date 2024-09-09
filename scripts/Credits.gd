extends CanvasLayer

var is_scrolling:bool = false
const scroll_speed:int = 20

func _process(delta: float) -> void:
	if is_scrolling:
		$ColorRect.position.y -= scroll_speed * delta


func _on_visibility_changed() -> void:
	if !visible:
		$ColorRect.position.y = 0
		is_scrolling = false
		$Timer.stop()
	if visible:
		$Timer.start()
		await $Timer.timeout
		is_scrolling = true
