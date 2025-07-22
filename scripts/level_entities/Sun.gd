extends Node2D

@onready var sprite: Sprite2D = $SunTexture


func _ready() -> void:
	SignalBus.level_entity_added.emit(self, "Sun")
	z_index = Utility.Z["Suns"]


func _physics_process(delta: float) -> void:
	rotate(deg_to_rad(1.5)*delta)
