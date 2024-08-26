extends Control

@export var player:NodePath

var grid_scale = GameSettings.borderValue/get_viewport_rect().size.x

# Called when the node enters the scene tree for the first time.
func _ready():
	player


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !player: return
