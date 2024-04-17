class_name Shield extends Sprite2D


@export var regen_speed:float = 2.5
@export var sp_max:int = 50

@onready var trans_length = get_parent().trans_length
@onready var shield_area = $shield_area

@onready var sp_current:float = sp_max
@onready var shieldActive:bool = true

func _ready():
	emit_signal("ready")


func _process(delta):
	if shieldActive == true and sp_current <= sp_max:
		sp_current += regen_speed * delta

func fadeout(): #Fades shield to 0 Alpha
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 0, trans_length)
	await tween.finished
	shield_area.set_monitoring.call_deferred(false)
	shield_area.set_monitorable.call_deferred(false)
	shieldActive = false

func fadein(): #Fades shield in to 255 Alpha
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self, "modulate:a", 1, trans_length)
	await tween.finished
	shield_area.set_monitoring.call_deferred(true)
	shield_area.set_monitorable.call_deferred(true)
	shieldActive = true
	
func shieldDie(): #Instantly turns off shield when health goes to 0
	shield_area.set_monitoring.call_deferred(false)
	shield_area.set_monitorable.call_deferred(false)
	self.visible = false
	shieldActive = false
	
func shieldAlive(): #Instant on shield
	shield_area.set_monitoring.call_deferred(true)
	shield_area.set_monitorable.call_deferred(true)
	self.visible = true
	shieldActive = true

func _on_shield_area_entered(area):
	if area.is_in_group("torpedo"): # and area.shooter != "player":
		area.queue_free()
		var damage_taken = area.damage
		sp_current -= damage_taken
		if sp_current <= 0:
			#get_parent().hp_current += sp_current #Passes extra damage to player hull health
			shieldDie()
			sp_current = 0
			await get_tree().create_timer(3).timeout
			shieldAlive()
	elif area.is_in_group("enemy"):
		get_parent().die()
