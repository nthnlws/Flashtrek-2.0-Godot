extends CanvasLayer

var screen_size:Vector2
var base_size = Vector2(1280, 720)

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	get_tree().get_root().connect("size_changed", Callable(self, "_on_window_size_changed"))
	adjust_canvas_layer_scale()
	
func _on_window_size_changed():
	adjust_canvas_layer_scale()
	
func adjust_canvas_layer_scale():
	screen_size = get_viewport().get_visible_rect().size
	base_size = Vector2(1280, 720)
	var scale_factor = screen_size / base_size
	scale = scale_factor
