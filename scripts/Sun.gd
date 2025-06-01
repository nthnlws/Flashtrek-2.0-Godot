extends Node2D

@onready var sprite: Sprite2D = $SunTexture


func _ready() -> void:
	Utility.mainScene.suns.append(self)


func _physics_process(delta: float) -> void:
	rotate(deg_to_rad(1.5)*delta)
