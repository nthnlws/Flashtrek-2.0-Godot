extends Resource
class_name ShipStatModifiers

signal DamageMultChanged(new_value: float)
signal EnergyCapacityChanged(new_value: float)
signal FireRateChanged(new_value: float)

signal ShieldMultChanged(new_value: float)
signal HullMultChanged(new_value: float)
signal SpeedMultChanged(new_value: float)
signal AgilityMultChanged(new_value: float)
signal AccelMultChanged(new_value: float)

signal WarpRangeChanged(new_value: int)
signal CargoCapacityChanged(new_value: int)

@export_group("Weapon Stats")
@export var DamageMult: float = 1:
	set(value):
		DamageMult = value
		DamageMultChanged.emit(value)
		
@export var EnergyCapacityMult: float = 1:
	set(value):
		EnergyCapacityMult = value
		EnergyCapacityChanged.emit(value)

@export var FireRateMult: float = 1:
	set(value):
		FireRateMult = value
		FireRateChanged.emit(value)

@export_group("Ship Stats")
@export var ShieldMult: float = 1:
	set(value):
		ShieldMult = value
		ShieldMultChanged.emit(value)

@export var HullMult: float = 1:
	set(value):
		HullMult = value
		HullMultChanged.emit(value)

@export var SpeedMult: float = 1:
	set(value):
		SpeedMult = value
		SpeedMultChanged.emit(value)

@export var AgilityMult: float = 1:
	set(value):
		AgilityMult = value
		AgilityMultChanged.emit(value)

@export var AccelMult: float = 1:
	set(value):
		AccelMult = value
		AccelMultChanged.emit(value)

@export_group("Navigation Stats")
@export var WarpRangeAdd: int = 0:
	set(value):
		WarpRangeAdd = value
		WarpRangeChanged.emit(value)

@export var CargoCapacityAdd: int = 0:
	set(value):
		CargoCapacityAdd = value
		CargoCapacityChanged.emit(value)
