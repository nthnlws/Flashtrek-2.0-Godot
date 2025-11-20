extends Node2D
class_name Sun

@onready var sprite: Sprite2D = $SunTexture


func _ready() -> void:
	z_index = Utility.Z["Suns"]

func _physics_process(delta: float) -> void:
	rotate(deg_to_rad(1.5)*delta)

func set_frame(index:int) -> void:
	sprite.frame = index
