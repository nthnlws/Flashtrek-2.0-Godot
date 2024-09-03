extends Node2D
@onready var player: Player = $Player


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player.global_position = Vector2(0, 500)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
