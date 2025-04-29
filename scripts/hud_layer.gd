extends CanvasLayer

@onready var canvas_modulate: CanvasModulate = $CanvasModulate

func _ready():
	SignalBus.entering_galaxy_warp.connect(fade_hud.bind("off"))
	SignalBus.entering_new_system.connect(fade_hud.bind("on"))
	
	
func fade_hud(state: String):
	if state == "off":
		create_tween().tween_property(canvas_modulate, "color", Color(1, 1, 1, 0), 2)
	else:
		var tween: Object = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(canvas_modulate, "color", Color(1, 1, 1, 1), 3.0)
