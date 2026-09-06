extends Node
class_name HealthComponent

var upgrades: ShipStatModifiers

@export var parent: Node
@export var shield: Shield
@export var hull_component: HullDamageReceiver
@export var is_on_player:bool = false
var alive:bool = true

signal ship_died(last_hit_event:HitEvent)
signal shield_off
signal shield_on

signal health_changed(new_value:float)
signal shield_changed(new_value:float)
signal health_max_changed(new_value:float)
signal shield_max_changed(new_value:float)

signal hull_damage_received
signal shield_damage_received(shooter:Node)

#region HP Variables
@export var HP_max: float = 150:
	set(value):
		HP_max = value
		health_max_changed.emit(value)
var HP_current:float = HP_max:
	set(value):
		HP_current = value
		health_changed.emit(value)

func resetHealthToMax() -> void:
	setCurrentHealth(getMaxHealth())

func getMaxHealth() -> float:
	if parent:
		return HP_max * upgrades.HullMult
	else:
		return HP_max

func getCurrentHP() -> float:
	return HP_current

func setMaxHealth(new_max: float) -> void:
	HP_max = new_max
	health_max_changed.emit(new_max)
	if HP_current > HP_max: # Reduce current HP if max reduced
		setCurrentHealth(new_max)
	if is_on_player:
		SignalBus.playerMaxHealthChanged.emit(HP_max)

func setCurrentHealth(new_HP: float) -> void:
	# No need to update current if already at max
	if SP_current == new_HP: return
	HP_current = clamp(new_HP, 0, HP_max)
	if is_on_player:
		SignalBus.playerHealthChanged.emit(HP_current)
#endregion


#region Hull Functions
var continuous_damage_accumulator: float = 0.0
const HITMARKER_DAMAGE_THRESHOLD: float = 10.0
func take_hull_damage(hit_event: HitEvent):
	hull_damage_received.emit(hit_event.get_shooter_node())
	HP_current -= hit_event.damage_amount
	
	if hit_event.is_continuous_damage:
		# --- Laser Logic ---
		continuous_damage_accumulator += hit_event.damage_amount
		
		if continuous_damage_accumulator >= HITMARKER_DAMAGE_THRESHOLD:
			Hitmarker.createDamageHitmarker(continuous_damage_accumulator, hit_event.hit_position, Hitmarker.TargetType.SELF)
			# Reset the accumulator
			continuous_damage_accumulator = 0.0
	else:
		# --- Torpedo / Instant Damage Logic ---
		Hitmarker.createDamageHitmarker(hit_event.damage_amount, hit_event.hit_position, Hitmarker.TargetType.SELF)
	
	if HP_current <= 0 and alive:
		HP_current = 0
		SP_current = 0
		alive = false
		regenTimeout = true
		ship_died.emit(hit_event)
#endregion


#region General Functions
func _ready() -> void:
	if is_on_player:
		call_deferred('initialize_hud')


func _process(delta: float) -> void:
	if SP_current < SP_max and regenTimeout == false:
		regen_shield(delta)
	if is_on_player:
		if get_parent().overdrive_active == true and shield.shieldActive == true:
			#Forces shieldActive to false when player is warping
			shield.shieldActive = false


func initialize_hud() -> void:
	SignalBus.playerMaxShieldChanged.emit(SP_max)
	SignalBus.playerShieldChanged.emit(SP_current)


#region Shield Functions
var regenTimeout:bool = false # Timeout
var regen_speed:float = 2.5

var SP_max:int = 50:
	set(value):
		SP_max = value
		shield_max_changed.emit(value)
var SP_current:float = SP_max:
	set(value):
		SP_current = value
		shield_changed.emit(value)

func resetShieldToMax() -> void:
	setCurrentShield(getMaxShield())

func setCurrentShield(new_value:float) -> void:
	shield_changed.emit(new_value)
	if is_on_player:
		SignalBus.playerShieldChanged.emit(new_value)
	SP_current = clamp(new_value, 0.0, SP_max)

func setMaxShield(new_max:float) -> void:
	shield_max_changed.emit(new_max)
	# Emit signals and check against stats if on player
	if is_on_player:
		SignalBus.playerMaxShieldChanged.emit(new_max)
		SP_max = new_max * upgrades.ShieldMult
	else:
		SP_max = new_max

func getMaxShield() -> float:
	if is_on_player:
		return SP_max * upgrades.ShieldMult
	else:
		return SP_max

func getCurrentSP() -> float:
	return SP_current


func take_shield_damage(hit_event:HitEvent) -> void:
	activate_regeneration_timeout()
	shield_damage_received.emit(hit_event.get_shooter_node())
	SP_current -= hit_event.damage_amount
	
	if hit_event.is_continuous_damage:
		# --- Laser Logic ---
		continuous_damage_accumulator += hit_event.damage_amount
		
		if continuous_damage_accumulator >= HITMARKER_DAMAGE_THRESHOLD:
			Hitmarker.createDamageHitmarker(continuous_damage_accumulator, hit_event.hit_position, Hitmarker.TargetType.SHIELD)
			# Reset the accumulator.
			continuous_damage_accumulator = 0.0
	else:
		# --- Torpedo / Instant Damage Logic ---
		Hitmarker.createDamageHitmarker(hit_event.damage_amount, hit_event.hit_position, Hitmarker.TargetType.SHIELD)
	
	if SP_current <= 0:
		shield_off.emit()
		if is_on_player:
			SignalBus.playerShieldOff.emit()
		activate_regeneration_timeout()


func regen_shield(delta: float) -> void:
	SP_current += regen_speed * delta


var active_timers:Array[Timer] = []
func activate_regeneration_timeout() -> void: #Turns off shield regen for 1 second
	regenTimeout = true
	for timer in active_timers:
		timer.stop()
	
	var timer = Timer.new()
	add_child(timer)
	active_timers.append(timer)
	timer.start()
	
	await timer.timeout
	regenTimeout = false
#endregion
