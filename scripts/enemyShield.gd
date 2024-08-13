#class_name Shield
extends Sprite2D

var damageTime:bool = false # Timeout
@onready var shieldActive:bool = true
@export var regen_speed:float = 2.5

@onready var trans_length:int = 1
@onready var shield_area:Area2D = $shield_area

# Enemy shield health variables
@export var sp_max:int = 50
@onready var sp_current:float = sp_max


func _ready():
	GameSettings.enemyShield = true
	self.position.y = -2
	self.scale = Vector2(3.611,2.833)
	
func _process(delta):
	if shieldActive == true and sp_current <= sp_max and damageTime == false:
		sp_current += regen_speed * delta
		sp_current = clamp(sp_current, 0, sp_max)
	if sp_current <= 0: shieldDie()
	
	if GameSettings.enemyShield != null:
		if GameSettings.enemyShield == false:
			visible = false
			shield_area.collision_layer = 0
			shield_area.collision_mask = 0
		elif GameSettings.enemyShield == true && shieldActive == true:
			visible = true
			shield_area.collision_layer = 3
			shield_area.collision_mask = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)
	
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
