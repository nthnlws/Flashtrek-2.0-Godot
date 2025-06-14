extends Camera3D

var move_speed: float = 100.0
var mouse_sensitivity: Vector2 = Vector2(0.2, 0.2)
var camera_rotation: Vector2 = Vector2.ZERO
var boost_multiplier: float = 4.0

@onready var ent_kelvin: Node3D = %Ent_Kelvin


func _process(delta: float) -> void:
	var target_position = ent_kelvin.global_transform.origin + Vector3(50, 25, 0)
	look_at(target_position, Vector3.UP)
