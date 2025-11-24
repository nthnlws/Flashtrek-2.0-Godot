extends CanvasLayer

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	anim.play("fade_in_long")
	

func fade_hud(system) -> void:
	anim.play("fade_in_long")

func galaxyFade() -> void:
	anim.play("galaxy_travel_fade_out")
