extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var tween = create_tween()
	tween.set_loops(-1)
	tween.tween_property($Shield, "modulate:a", 0, 1)
	tween.tween_property(self, "modulate:a", 1, 1)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
