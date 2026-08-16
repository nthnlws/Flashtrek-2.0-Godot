extends Node
class_name EnergyComponent

signal energy_changed(current: float)
signal max_energy_changed(max: float)
signal energy_depleted

@export var base_max_energy: float = 150.0
@export var max_energy: float = 150.0

var current_energy: float = 0.0
var is_regen_locked: bool = false


func resetEnergyToMax() -> void:
	setCurrentEnergy(base_max_energy)


func setCurrentEnergy(new_current:float):
	var old_value: float = current_energy
	current_energy = clamp(new_current, 0.0, max_energy)
	
	if current_energy != old_value:
		energy_changed.emit(current_energy)
	
	if current_energy <= 0.0 and old_value > 0.0:
		energy_depleted.emit()

func setMaxEnergy(new_max:float):
	max_energy = max(0.0, new_max)
	max_energy_changed.emit(max_energy)
	# Ensure current energy doesn't exceed new max
	if current_energy > max_energy:
		current_energy = max_energy


func _ready() -> void:
	current_energy = max_energy
	
	# Initialize HUD values
	SignalBus.playerMaxEnergyChanged.emit.call_deferred(max_energy)
	SignalBus.playerEnergyChanged.emit.call_deferred(current_energy)


## Attempt to spend energy. Returns true if successful.
func request_consume(amount: float) -> bool:
	if current_energy >= amount:
		return true
	else: 
		return false

func consume_energy(amount: float) -> void:
	current_energy -= amount
	energy_depleted.emit()


## Instantly add energy
func gain(amount: float) -> void:
	current_energy += amount


## Logic for passive regeneration.
func regenerate(delta: float, rate: float) -> void:
	if is_regen_locked:
		return
		
	if current_energy < max_energy:
		current_energy += rate * delta


## Disables regeneration for a set duration (in seconds)
func lock_regeneration(duration: float) -> void:
	is_regen_locked = true
	var timer: SceneTreeTimer = get_tree().create_timer(duration)
	timer.timeout.connect(func(): is_regen_locked = false)
