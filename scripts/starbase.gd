extends Node2D
@onready var sprite = $Sprite2D


func _ready():
	rotation_degrees = 40
	
func _physics_process(delta):
	pass

func _process(delta):
	rotate(deg_to_rad(1.5)*delta)
