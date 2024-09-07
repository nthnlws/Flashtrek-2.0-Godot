extends Node


var poi_nodes: Array = []

# Function to add a POI
func add_poi(node: Node2D, poi_type: String) -> void:
	# Create a dictionary with node and type
	var poi = {
		"node": node,
		"type": poi_type
	}
	# Add the dictionary to the poi_nodes array
	poi_nodes.append(poi)
	

func _ready() -> void:
	if get_tree().get_current_scene().name == "Game":
		var planets = get_node("/root/Game/Level/Planets").get_children()
		var starbase = get_node("/root/Game/Level/Starbase")
		var hostiles = get_node("/root/Game/Level/Hostiles").get_children()
		
		for p in planets:
			add_poi(p, "planet")
	#print(poi_nodes)
		
func _process(delta: float) -> void:
	#print(poi_nodes)
	pass
