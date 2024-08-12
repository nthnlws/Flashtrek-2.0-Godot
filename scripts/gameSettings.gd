
extends Node

#Options
var gameVolume: float = 100.0
var gameSize: int
var vSync: bool = true

#Cheats
var unlimitedEnergy: bool = false
var unlimitedHealth: bool = false
var unlimitedShield: bool = false
var teleportCoords: Vector2

#Player
var playerShield: bool
var laserRangeOverride: bool = false
var laserRange: int
var laserDamageOverride: bool = false
var laserDamage: int
var speedOverride: bool  = false
var maxSpeed: int

#Enemy
var enemyShield: bool
var enemyMovement: bool = true

#World
var borderToggle: bool = false
var borderValue: int
