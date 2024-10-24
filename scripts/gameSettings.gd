
extends Node

var loadNumber: int = 0
var menuStatus: bool = false


#Cheats
var unlimitedEnergy: bool = false
var unlimitedHealth: bool = false
var unlimitedShield: bool = false
var noCollision: bool = false
var teleportCoords: Vector2

#Player
var playerShield: bool = true
var laserRangeOverride: bool = false
var laserRange: int
var laserDamageOverride: bool = false
var laserDamage: int
var speedOverride: bool  = false
var maxSpeed: int
var playerDirection

#Enemy
var enemyShield: bool = true
var enemyMovement: bool = true

#World
var borderToggle: bool = false
var borderValue: int
var gameVolume: float = 100.0
var vSyncSetting: bool = true
var HUDscale:int = 100:
	set(value):
		HUDscale = value
		SignalBus.HUDchanged.emit()
	get:
		return HUDscale
