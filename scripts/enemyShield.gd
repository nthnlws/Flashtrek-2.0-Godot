#class_name Shield
extends Sprite2D

enum EnemyType {BIRD_OF_PREY, ENTERPRISETOS}
enum ShieldDeathLength {TEMP, PERM}

var current_enemy_type: int

var processing_active:bool = true
var damageTime:bool = false # Timeout
var shieldActive:bool = true
@export var regen_speed:float = 2.5

@onready var shield_area:Area2D = $shield_area

# Enemy shield health variables
@export var sp_max:int = 50
var sp_current:float = sp_max:
	get: return clamp(sp_current, 0, sp_max)

func _ready():
	SignalBus.enemy_shield_cheat_state.connect(shieldDie)
	
	
func scale_shield():
	#Sets scale and position for enemy type
	match current_enemy_type:
		EnemyType.BIRD_OF_PREY:
			self.position.y = -2
			self.scale = Vector2(3.611, 2.833)
		EnemyType.ENTERPRISETOS:
			self.position.y = 3
			self.scale = Vector2(2.5, 2.5)
	
func _process(delta):
	if processing_active:
		if shieldActive and sp_current <= sp_max and damageTime == false:
			sp_current += regen_speed * delta
		if sp_current <= 0.05 and shieldActive:
			shieldDie(ShieldDeathLength.TEMP)
		
		if GameSettings.enemyShield != null:
			if GameSettings.enemyShield == false:
				visible = false
				shield_area.collision_layer = 0
				shield_area.collision_mask = 0
			elif GameSettings.enemyShield == true && shieldActive == true:
				visible = true
				shield_area.collision_layer = 3
				shield_area.collision_mask = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)
	
func shieldDie(death_length): #Turns shield off when health goes to 0
	shield_area.set_monitoring.call_deferred(false)
	shield_area.set_monitorable.call_deferred(false)
	self.visible = false
	shieldActive = false
	if death_length == ShieldDeathLength.TEMP:
		await get_tree().create_timer(3).timeout
		shieldAlive()
	
func shieldAlive(): #Instant on shield
	shield_area.set_monitoring.call_deferred(true)
	shield_area.set_monitorable.call_deferred(true)
	self.visible = true
	shieldActive = true
	sp_current = 0.1

func damageTimeout(): #Turns off shield regen for 1 second after damage taken
	damageTime = true
	if $Timer.is_stopped() == false: # If timer is already running, restarts timer fresh
		$Timer.stop()
		$Timer.start()
		await $Timer.timeout
		damageTime = false
	if $Timer.is_stopped() == true: # Starts timer if it is not already
		$Timer.start()
		await $Timer.timeout
		damageTime = false
	
func _on_shield_area_entered(area): #Torpedo damage
	if area.is_in_group("projectile") and area.shooter != "enemy":
		area.queue_free()
		var damage_taken = area.damage
		sp_current -= damage_taken
		damageTimeout()
	elif area.is_in_group("enemy"):
		pass
