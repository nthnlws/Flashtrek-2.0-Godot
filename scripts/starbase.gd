extends Node2D
@onready var sprite = $Sprite2D


func _init():
	Utility.mainScene.starbase.append(self)
	
func _ready():
	rotation_degrees = 40
	
func _physics_process(delta):
	rotate(deg_to_rad(1.5)*delta)
