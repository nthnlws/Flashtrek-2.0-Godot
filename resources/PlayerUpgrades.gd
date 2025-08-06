extends Resource
class_name PlayerUpgrades

@export_group("Weapon Stats")
@export var DamageMult: float = 1
@export var EnergyCapacityMult: float = 1
@export var FireRateMult: float = 1

@export_group("Ship Stats")
@export var ShieldMult: float = 1
@export var HullMult: float = 1
@export var SpeedMult: float = 1
@export var RotateMult: float = 1
@export var AccelMult: float = 1

@export_group("Navigation Stats")
@export var WarpRangeAdd: int = 0
@export var CargoCapacityAdd:int = 0
