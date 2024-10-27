extends Node

var current_root: Node
var future_system: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.galaxy_map_clicked.connect(system_changer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func system_changer(clicked_system):
	print(clicked_system)
	#current_root = get_tree().current_scene
	#future_system = clicked_system
	#print(current_root)
	#print(future_system)
