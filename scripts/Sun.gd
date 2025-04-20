extends Node2D

@onready var sprite: Sprite2D = $SunTexture


func _ready():
	Utility.mainScene.suns.append(self)


func _physics_process(delta):
	rotate(deg_to_rad(1.5)*delta)
