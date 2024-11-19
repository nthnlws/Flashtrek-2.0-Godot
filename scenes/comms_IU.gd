extends Control

var current_mission: Dictionary = {}
@onready var comms_message = $Comms_message

var button_array = []

var player_position:Vector2
var comm_distance:float

var systems: Array
var cargo_types: Array = [
	"Dilithium Crystals",
	"Trilithium Resin",
	"Medical Supplies",
	"Phaser Components",
	"Food Rations",
	"Isolinear Chips",
	"Antimatter Pods",
	"Bioneural Gel Packs",
	"Quantum Torpedoes",
	"Romulan Ale",
	"Scientific Equipment",
	"Exotic Plants",
	"Cultural Artifacts",
	"Raw Latinum",
	"Terraforming Supplies",
	"Engineering Tools",
	"Warp Coils",
	"Diplomatic Documents",
	"Starfleet Uniforms",
	"Holodeck Matrix Components",
	"Rare Minerals",
	"Subspace Relay Components",
	"Vaccines",
	"Graviton Stabilizers",
	"Tritanium",
	"Biomimetic Gel",
	"Sensor Arrays",
	"Temporal Artifacts",
	"Borg Debris",
	"Rare Spices or Foods",
	"Alien Animal Specimens",
	"Subspace Dampeners",
	"Energy Shields",
	"Repair Drones",
	"Navigational Charts",
	"Cryogenic Pods",
	"Experimental Technology",
	"Klingon Bloodwine",
	"Xenobiological Samples"]

var planet_names: Array = [
	"Vulcan",
	"Qo'noS",
	"Andoria",
	"Betazed",
	"Cardassia Prime",
	"Risa",
	"Bajor",
	"Ferenginar",
	"Tellar",
	"Trill",
	"Romulus",
	"Delta Vega"]

var confirmation_messages = [
	"Will you take on this task?",
	"Do you agree to these terms?",
	"Are you ready to proceed?",
	"Shall we begin the mission?",
	"Is this assignment acceptable?",
	"Can we count on your assistance?",
	"Do you confirm your participation?"]

var current_planet
var target_system
var ship_name: String
var target_planet
var item_name
var random_confirm_query

func _ready():
	#Signal Connections

	SignalBus.Quad2_clicked.connect(accept_mission)
	SignalBus.Quad3_clicked.connect(toggle_comms)
	button_array = get_tree().get_nodes_in_group("comms_button")
	for button in button_array:
		button.gui_input.connect(handle_button_click.bind(button))
	
	# Mission text setup
	var planet_node = Utility.mainScene.planets[0]
	var detection_radius = planet_node.get_node("CommArea").get_node("CollisionShape2D")
	ship_name = Utility.mainScene.player[0].player_name
	systems = Utility.mainScene.systems
	comm_distance = detection_radius.shape.radius*planet_node.scale.x

	#set_dynamic_text()

func handle_button_click(event, button):
	if event.is_action_pressed("left_click"):
		if button.name == "reroll_button":
			randomize_mission()
			set_dynamic_text()
		elif button.name == "close_button":
			toggle_comms()
	

func set_dynamic_text():
	var data = {
		"planet": current_planet,
		"ship_name": ship_name,
		"target_planet": target_planet,
		"target_system": target_system,
		"item_name": item_name,
		"random_confirm_query": random_confirm_query
	}
	var template_text = "Welcome to {planet}, USS {ship_name}, {target_planet} in the {target_system} system needs a shipment of {item_name}. {random_confirm_query}"
	var formatted_text = template_text.format(data)
	comms_message.text = formatted_text

func toggle_comms():
	if visible == true: visible = false
	
	# Only toggles on if within required distance
	elif check_distance_to_planets():
		randomize_mission()
		set_dynamic_text()
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
			current_planet = planet.name
			return true

	# No planet is within the specified distance
	return false

func randomize_mission():
	target_planet = planet_names.pick_random()
	target_system = systems.pick_random()
	item_name = cargo_types.pick_random()
	random_confirm_query = confirmation_messages.pick_random()

func accept_mission():
	if visible:
		current_mission["mission_type"] = "Cargo Delivery"
		current_mission["cargo"] = item_name
		current_mission["target_system"] = target_system
		current_mission["target_planet"] = target_planet
		visible = false
		SignalBus.missionAccepted.emit(current_mission)
		#TODO Fade "accepted mission" banner
