extends Control

var current_mission: Dictionary = {}
@onready var comms_message = $Comms_message
@onready var player = Utility.mainScene.player

var button_array = []
var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

var comm_distance:float

var systems: Array = []
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

var cargo_full_messages: Array = [
	"[color=#f06c82]Cargo hold is already full.[/color] Return when you've delivered the goods.",
	"[color=#f06c82]Mission queue is full.[/color] Complete your current objectives first.",
	"[color=#f06c82]No room for more cargo.[/color] Clear your hold before accepting another mission.",
	"[color=#f06c82]You’re already assigned a mission.[/color] Finish it before taking on more.",
	"[color=#f06c82]Your current mission needs completion first.[/color] Come back later.",
	"[color=#f06c82]Ship’s storage is maxed out.[/color] Offload before taking another task.",
	"[color=#f06c82]No additional cargo can be loaded.[/color] Finish your delivery first.",
	"[color=#f06c82]One task at a time![/color] Complete your current mission before returning."]

var confirmation_messages: Array = [
	"Will you take on this task?",
	"Do you agree to these terms?",
	"Are you ready to proceed?",
	"Shall we begin the mission?",
	"Is this assignment acceptable?",
	"Can we count on your assistance?",
	"Do you confirm your participation?"]

var current_planet: String
var target_system: String
var ship_name: String
var target_planet: String
var item_name: String
var random_confirm_query: String

func _ready():
	#Signal Connections
	SignalBus.Quad2_clicked.connect(accept_mission)
	SignalBus.Quad3_clicked.connect(open_comms)
	SignalBus.entering_galaxy_warp.connect(close_comms)
	button_array = get_tree().get_nodes_in_group("comms_button")
	for button in button_array:
		button.gui_input.connect(handle_button_click.bind(button))
	
	# Mission text setup
	var planet_node: Node2D = Utility.mainScene.planets[0]
	var detection_radius: CollisionShape2D = planet_node.get_node("CommArea").get_node("CollisionShape2D")
	
	ship_name = player.player_name
	systems = Utility.mainScene.systems
	comm_distance = detection_radius.shape.radius*planet_node.scale.x

	# Initialize sound array
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()


func handle_button_click(event, button):
	if event.is_action_pressed("left_click"):
		if button.name == "reroll_button":
			Utility.play_click_sound(0)
			if current_mission.is_empty():
				randomize_mission()
				set_dynamic_text()
		elif button.name == "close_button":
			Utility.play_click_sound(0)
			close_comms()
	

func set_dynamic_text():
	if player.current_cargo + 1 <= player.base_cargo_size:
		var data: Dictionary = {
			"planet": "[color=#6699CC]" + current_planet + "[/color]",
			"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
			"target_planet": "[color=#FFCC66]" + target_planet + "[/color]",
			"target_system": "[color=#FFCC66]" + target_system + "[/color]",
			"item_name": "[color=#1DCC4B]" + item_name + "[/color]",
			"random_confirm_query": random_confirm_query
			}
		var template_text: String = "Welcome to {planet}, {ship_name}, {target_planet} in the {target_system} system needs a shipment of {item_name}. {random_confirm_query}"
		var formatted_text: String = template_text.format(data)
		comms_message.bbcode_text = formatted_text
	
	else:
		var data: Dictionary = {
			"planet": "[color=#6699CC]" + current_planet + "[/color]",
			"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
			"random_deny": cargo_full_messages.pick_random()
			}
			
		var template_text: String = "Welcome to {planet}, {ship_name}, {random_deny}"
		var formatted_text: String = template_text.format(data)
		comms_message.bbcode_text = formatted_text

func open_comms():
	# Only toggles on if within required distance
	if check_distance_to_planets() and player.warping_active == false:
		randomize_mission()
		set_dynamic_text()
		self.visible = true

func close_comms():
	if visible == true:
		visible = false
		
		
func check_distance_to_planets() -> bool:
	var player_position: Vector2 = player.global_position
	# Iterate through the planets array
	for planet in Utility.mainScene.planets:
		if not planet:  # Ensure the planet node is valid
			continue

		var planet_position: Vector2 = planet.global_position
		var distance: float = player_position.distance_to(planet_position)
		
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
	if visible and player.current_cargo + 1 <= player.base_cargo_size:
		# Update text to "accepted"
		var data: Dictionary = {
			"target_planet": "[color=#FFCC66]" + target_planet + "[/color]",
			"target_system": "[color=#FFCC66]" + target_system + "[/color]",
			}
			
		var template_text: String = "Mission accepted! Head to {target_planet} in the {target_system} system."
		var formatted_text: String = template_text.format(data)
	
		comms_message.bbcode_text = formatted_text
		current_mission["mission_type"] = "Cargo Delivery"
		current_mission["cargo"] = item_name
		current_mission["target_system"] = target_system
		current_mission["target_planet"] = target_planet
		SignalBus.missionAccepted.emit(current_mission)
		#await get_tree().create_timer(2.0).timeout
		#visible = false
		
		player.current_cargo += 1
