class_name Shield extends Sprite2D

@onready var trans_length = get_parent().trans_length
@onready var shield_area = $shield_area

func _process(delta):
	pass

func fadeout(): #Fades shield to 0 Alpha
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 0, trans_length)
	await tween.finished
	shield_area.monitoring = false #Turns collision off for shield
	shield_area.monitorable = false

func fadein(): #Fades shield in to 255 Alpha
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 1, trans_length)
	await tween.finished
	shield_area.monitoring = true # Turns collision on for shield
	shield_area.monitorable = true
