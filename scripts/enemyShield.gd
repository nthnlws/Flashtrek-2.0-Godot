#class_name Shield
extends Sprite2D

var damageTime:bool = false
@onready var shieldActive:bool = true
@export var regen_speed:float = 2.5

@onready var trans_length:int = 1
@onready var shield_area:Area2D = $shield_area

# Enemy shield health variables
@export var sp_max:int = 50
@onready var sp_current:float = sp_max


func _ready():
	self.position.y = -2
	self.scale = Vector2(3.611,2.833)
	
func _process(delta):
	if shieldActive == true and sp_current <= sp_max and damageTime == false:
		sp_current += regen_speed * delta
	if sp_current <= 0: shieldDie()
	if sp_current > sp_max: sp_current = sp_max
	
func shieldDie(): #Instantly turns off shield when health goes to 0
	shield_area.set_monitoring.call_deferred(false)
	shield_area.set_monitorable.call_deferred(false)
	self.visible = false
	shieldActive = false
	sp_current = 0.00001
	await get_tree().create_timer(3).timeout
	shieldAlive()
	
func shieldAlive(): #Instant on shield
	shield_area.set_monitoring.call_deferred(true)
	shield_area.set_monitorable.call_deferred(true)
	self.visible = true
	shieldActive = true

func damageTimeout(): #Turns off shield regen for 1 second after damage taken
	if damageTime == false:
		damageTime = true
		await get_tree().create_timer(1).timeout
		damageTime = false
	
func _on_shield_area_entered(area): #Torpedo damage
	if area.is_in_group("torpedo") and area.shooter != "enemy":
		area.queue_free()
		var damage_taken = area.damage
		sp_current -= damage_taken
		damageTimeout()
	elif area.is_in_group("enemy"):
		pass
