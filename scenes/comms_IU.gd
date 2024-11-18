extends Control

@onready var button = $TextureButton
@onready var comms_message = $Comms_message

var player_position:Vector2
var comm_distance:float


# Called when the node enters the scene tree for the first time.
func _ready():
	comm_distance = Utility.mainScene.planets[0].get_node("CommArea").get_node("CollisionShape2D").shape.radius
	
	SignalBus.Quad3_clicked.connect(toggle_comms)
	button.gui_input.connect(handle_button_click)
	set_dynamic_text(
		"Alpha Quadrant",
		"Enterprise",
		"Vulcan",
		"Solar System",
		"Dilithium Crystals",
		"Do you accept this mission"
	)

func handle_button_click(event):
	if event.is_action_pressed("left_click"):
		toggle_comms()
	

func set_dynamic_text(system: String, ship_name: String, planet: String, system_name: String, item_name: String, random_confirm_query: String):
	var data = {
		"system": system,
		"ship_name": ship_name,
		"planet": planet,
		"system_name": system_name,
		"item_name": item_name,
		"random_confirm_query": random_confirm_query
	}
	var template_text = "Welcome to {system}, USS {ship_name}, {planet} in the {system_name} needs a shipment of {item_name}. {random_confirm_query}?"
	var formatted_text = template_text.format(data)
	comms_message.text = formatted_text

func toggle_comms():
	if visible == true: visible = false
	
	# Only toggles on if within required distance
	elif check_distance_to_planets():
		self.visible = true

func check_distance_to_planets() -> bool:
	player_position = Utility.mainScene.player[0].global_position
	# Iterate through the planets array
	for planet in Utility.mainScene.planets:
		if not planet:  # Ensure the planet node is valid
			continue

		var planet_position = planet.global_position
		var distance = player_position.distance_to(planet_position)
		
		# Check if the distance is within the threshold
		if distance <= comm_distance:
			return true  # Or store the planet for further use

	# No planet is within the specified distance
	return false
