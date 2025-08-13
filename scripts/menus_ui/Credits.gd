extends CanvasLayer

var is_scrolling:bool = false
var target_y: float = 0.0

@export var closeButton:Button

signal closed_credits
const scroll_speed:int = 20

func _ready() -> void:
	target_y = $ColorRect.position.y
	_on_visibility_changed()
	
func _process(delta: float) -> void:
	if is_scrolling:
		# Set the target position as it moves upwards
		target_y -= scroll_speed * delta
		# Use lerp to smooth the transition
		$ColorRect.position.y = lerp($ColorRect.position.y, target_y, 5 * delta)
	if $ColorRect.position.y < -460:
		is_scrolling = false


func _on_visibility_changed() -> void:
	if !visible:
		$ColorRect.position.y = 0
		target_y = 0
		is_scrolling = false
		$Timer.stop()
	if visible:
		$Timer.start()
		await $Timer.timeout
		is_scrolling = true


func _on_close_button_pressed() -> void:
	closed_credits.emit()
