extends Node
class_name HealthComponent

var Stats: PlayerUpgrades = PlayerUpgrades.new()
var ship_stats:Dictionary = Utility.PLAYER_SHIP_STATS.values()[Utility.starting_ship]

@export var shield: Shield
@onready var is_on_player:bool = get_parent() is Player
var alive:bool = true

signal ship_died
signal shield_off
signal shield_on

signal hull_health_changed
signal shield_health_changed

#region HP Variables
@export var HP_max: float = 150:
	set(value):
		HP_max = value
		if hp_current > get_max_HP(HP_max): # Reduce current HP if max reduced
			hp_current = value
		if is_on_player:
			SignalBus.playerMaxHealthChanged.emit(get_max_HP(HP_max))
	get:
		return get_max_HP(HP_max)
func get_max_HP(new_value:float) -> float:
	if Stats:
		return new_value * Stats.HullMult
	else:
		return new_value

var hp_current:float = HP_max:
	set(value):
		if hp_current == value: return
		hp_current = clamp(value, 0, HP_max)
		if is_on_player:
			SignalBus.playerHealthChanged.emit(hp_current)
#endregion

#region Hull Functions
var continuous_damage_accumulator: float = 0.0
const HITMARKER_DAMAGE_THRESHOLD: float = 10.0
func take_hull_damage(hit_event: HitEvent):
	hull_health_changed.emit()
	hp_current -= hit_event.damage_amount
	
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
	
	if hp_current <= 0 and alive:
		hp_current = 0
		sp_current = 0
		alive = false
		regenTimeout = true
		ship_died.emit()
#endregion


#region General Functions
func _ready() -> void:
	if is_on_player:
		call_deferred('initialize_hud')


func _process(delta: float) -> void:
	if sp_current < SP_max and regenTimeout == false:
		regen_shield(delta)
	if is_on_player:
		if get_parent().overdrive_active == true and shield.shieldActive == true:
			#Forces shieldActive to false when player is warping
			shield.shieldActive = false


func initialize_hud() -> void:
	SignalBus.playerMaxShieldChanged.emit(SP_max)
	SignalBus.playerShieldChanged.emit(sp_current)


func handle_damage_taken(hit_event:HitEvent) -> void:
	if Navigation.in_galaxy_warp:
		return
	
	if hit_event.hit_shield:
		if shield.shieldActive:
			take_shield_damage(hit_event)
	elif hit_event.hit_hull:
		if !shield.shieldActive:
			take_hull_damage(hit_event)
#endregion


#region Shield Variables
var regenTimeout:bool = false # Timeout
var regen_speed:float = 2.5

var SP_max:int = 50:
	set(value):
		SP_max = set_shield_max(value)
var sp_current:float = SP_max:
	set(value): 
		if sp_current == value: return
		sp_current = set_shield_value(value)
#endregion

#region Shield Functions
func take_shield_damage(hit_event:HitEvent) -> void:
	activate_regeneration_timeout()
	shield_health_changed.emit()
	sp_current -= hit_event.damage_amount
	
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
	
	if sp_current <= 0:
		shield_off.emit()
		SignalBus.playerShieldOff.emit()
		activate_regeneration_timeout()


func set_shield_value(value:float) -> float:
	shield_health_changed.emit()
	if is_on_player:
		SignalBus.playerShieldChanged.emit(value)
	return clamp(value, 0.0, SP_max)


func set_shield_max(value:float) -> float:
	if is_on_player:
		SignalBus.playerMaxShieldChanged.emit(value)
		value = value * Stats.ShieldMult
	return value


func regen_shield(delta: float) -> void:
	sp_current += regen_speed * delta

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
