# Health variables
@export var base_max_HP: int = 150:
	set(value):
		base_max_HP = value
		SignalBus.playerMaxHealthChanged.emit(value)
var max_HP:int:
	get:
		return PlayerUpgrades.HullAdd + (base_max_HP * PlayerUpgrades.HullMult)
		
var hp_current:float = max_HP:
	set(value):
		hp_current = clamp(value, 0, max_HP)
		SignalBus.playerHealthChanged.emit(hp_current)
