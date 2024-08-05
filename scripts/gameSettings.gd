extends Node2D

#Options
var gameVolume: float = 100.0
var gameSize: Vector2
var vSync: bool = true

#Cheats
var unlimitedEnergy: bool = false
var unlimitedHealth: bool = false
var unlimitedShield: bool = false

#Player
var playerShield: bool
var laserOverride: bool
var laserDamage: int
var speedOverride: bool
var maxSpeed: int

#Enemy
var enemyShield: bool
var enemyMovement: bool = true

#World
var borderToggle: bool = false
var borderValue: int
