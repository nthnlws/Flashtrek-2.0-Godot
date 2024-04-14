class_name Shield extends Sprite2D

@onready var trans_length = get_parent().trans_length
@onready var shield_area = $shield_area

@onready var max_health:int = 50
@onready var shield_current:int = max_health

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
	
func shieldDie(): #Instantly turns off shield when health goes to 0
	shield_area.monitoring = false
	shield_area.monitorable = false
	self.visible = false
	
func shieldAlive(): #Instant on shield
	shield_area.monitoring = true
	shield_area.monitorable = true
	self.visible = true

func _on_shield_area_entered(area):
	if area.is_in_group("torpedo"): #and area.shooter != "player":
		area.queue_free()
		shield_current -= 20
		print("Shield: " + str(shield_current))
		if shield_current <= 0:
			shieldDie()
			await get_tree().create_timer(2).timeout
			shield_current = max_health
			#shieldAlive()
