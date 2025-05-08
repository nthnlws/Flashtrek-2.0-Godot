extends Control

@onready var comms_message = $Comms_message
@onready var player = Utility.mainScene.player

var button_array = []
var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

var comm_distance:float
var pending_mission: Dictionary
var completedUIdisplay: bool # Var to lock new mission select until menu closed after completion

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

var cargo_full_messages: Array = [
	"[color=#f06c82]Cargo hold is already full.[/color] Return when you've delivered the goods.",
	"[color=#f06c82]Mission queue is full.[/color] Complete your current objectives first.",
	"[color=#f06c82]No room for more cargo.[/color] Clear your hold before accepting another mission.",
	"[color=#f06c82]You’re already assigned a mission.[/color] Finish it before taking on more.",
	"[color=#f06c82]Your current mission needs completion first.[/color] Come back later.",
	"[color=#f06c82]Ship’s storage is maxed out.[/color] Offload before taking another task.",
	"[color=#f06c82]No additional cargo can be loaded.[/color] Finish your delivery first.",
	"[color=#f06c82]One task at a time![/color] Complete your current mission before returning."]

var confirmation_accept: Array = [
	"Will you take on this task?",
	"Do you agree to these terms?",
	"Are you ready to proceed?",
	"Shall we begin the mission?",
	"Is this assignment acceptable?",
	"Can we count on your assistance?",
	"Do you confirm your participation?"]

var confirmation_complete: Array = [
	"Ready to complete the assignment?",
	"Prepared to proceed with the task.",
	"All systems go, proceed with beam.",
	"Acknowledged. Moving to final phase.",
	"Cargo confirmed, beam it over.",
	"Orders understood, ready to receive cargo.",
	"Initiating final mission steps.",
]
var federation_thankYou: Array = [
	"Your delivery has arrived. Starfleet commends your service.",
	"Shipment secured. We appreciate your reliability.",
	"Thank you. The Federation acknowledges your efforts.",
	"Mission complete. Your record has been updated.",
	"Excellent work. Cargo confirmed and logged.",]
var klingon_thankYou: Array = [
	"The cargo is delivered. You have done honor to this task.",
	"Your duty is fulfilled. Qapla’!",
	"Well fought. The shipment has arrived intact.",
	"You have earned your reward in glory and goods.",
	"Delivery made. Strength is proven through action.",]
var romulan_thankYou: Array = [
	"Your task is complete. Efficiency is... noted.",
	"Delivery received. The Empire is satisfied.",
	"You’ve served the mission well—for now.",
	"Shipment secured. Your discretion is appreciated.",
	"Another successful operation. You may continue.",]

var current_planet: Node2D
var ship_name: String
var random_confirm_query: String

func _ready():
	#Signal Connections
	SignalBus.enteredPlanetComm.connect(_enter_comms)
	SignalBus.exitedPlanetComm.connect(_exit_comms)
	SignalBus.Quad2_clicked.connect(handle_cargo_beam)
	SignalBus.Quad3_clicked.connect(open_comms)
	SignalBus.entering_galaxy_warp.connect(close_comms)
	button_array = get_tree().get_nodes_in_group("comms_button")
	for button in button_array:
		button.gui_input.connect(handle_UI_click.bind(button))
	
	# Mission text setup
	var planet_node: Node2D = Utility.mainScene.planets[0]
	var detection_radius: CollisionShape2D = planet_node.get_node("CommArea").get_node("CollisionShape2D")
	
	ship_name = player.player_name
	comm_distance = detection_radius.shape.radius*planet_node.scale.x

	# Initialize sound array
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()


func handle_UI_click(event: InputEvent, button: TextureButton):
	if event.is_action_pressed("left_click"):
		if button.name == "reroll_button":
			completedUIdisplay = false
			Utility.play_click_sound(0)
			var current_mission = generate_mission()
			set_mission_text(current_mission)
		elif button.name == "close_button":
			Utility.play_click_sound(0)
			close_comms()
	

func set_mission_text(mission_data: Dictionary):
	# New mission pickup
	if player.has_mission == false: 
		var data: Dictionary = {
			"planet": "[color=#6699CC]" + current_planet.name + "[/color]",
			"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
			"target_planet": "[color=#FFCC66]" + mission_data.planet + "[/color]",
			"target_system": "[color=#FFCC66]" + mission_data.system + "[/color]",
			"item_name": "[color=#1DCC4B]" + mission_data.cargo + "[/color]",
			"random_confirm_query": mission_data.message,
			}
		var template_text: String = "Welcome to {planet}, {ship_name}, {target_planet} in the {target_system} system needs a shipment of {item_name}. {random_confirm_query}"
		var formatted_text: String = template_text.format(data)
		comms_message.bbcode_text = formatted_text
	
	# Player already has cargo/mission
	else:
		var data: Dictionary = {
			"planet": "[color=#6699CC]" + current_planet.name + "[/color]",
			"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
			}
		# Comms planet is same as mission destination
		if current_planet.name == player.current_mission.planet:
			data.random_accept = confirmation_complete.pick_random()
			var template_text: String = "Welcome to {planet}, {ship_name}, {random_accept}"
			var formatted_text: String = template_text.format(data)
			comms_message.bbcode_text = formatted_text
			
		# Wrong planet for mission
		else:
			data.random_deny = cargo_full_messages.pick_random()
				
			var template_text: String = "Welcome to {planet}, {ship_name}, {random_deny}"
			var formatted_text: String = template_text.format(data)
			comms_message.bbcode_text = formatted_text
			
	
func open_comms():
	if visible:
		self.visible = false
		completedUIdisplay = false
	# Only toggles on if within required distance
	elif current_planet and player.warping_active == false:
		self.visible = true
		#if player.has_mission == false:
		var mission_data = generate_mission()
		set_mission_text(mission_data)
			

func close_comms():
	if visible == true:
		completedUIdisplay = false
		visible = false
		
		

func generate_mission():
	# Get random system
	var system_keys: Array = Navigation.systems
	var random_system_name = system_keys.pick_random()
	while random_system_name == Navigation.currentSystem:
		random_system_name = system_keys.pick_random()
	
	# Get random planet from picked system
	var planet_list: Array = Navigation.all_systems_data[str(random_system_name)].planet_data
	var random_planet: String = str(planet_list.pick_random().name)
	
	var item_name: String = cargo_types.pick_random()
	var random_confirm_query: String = confirmation_accept.pick_random()
	
	var misson_data: Dictionary = {
		"mission_type": "Cargo delivery",
		"system": random_system_name,
		"planet": random_planet,
		"cargo": item_name,
		"message": random_confirm_query,
	}
	
	pending_mission = misson_data
	return misson_data

func handle_cargo_beam():
	# Accept new mission
	if pending_mission and visible and player.has_mission == false and completedUIdisplay == false:
		# Update text to "accepted"
		var data: Dictionary = {
			"target_planet": "[color=#FFCC66]" + pending_mission.planet + "[/color]",
			"target_system": "[color=#FFCC66]" + pending_mission.system + "[/color]",
			}
			
			
		var template_text: String = "Mission accepted! Head to {target_planet} in the {target_system} system."
		var formatted_text: String = template_text.format(data)
	
		comms_message.bbcode_text = formatted_text
		SignalBus.missionAccepted.emit(pending_mission)
		
	# Succesfull mission complete
	elif visible and player.has_mission and current_planet.name == player.current_mission.planet:
		completedUIdisplay = true
		var data: Dictionary = {
			"planet": "[color=#6699CC]" + current_planet.name + "[/color]",
			"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
			}
		# Pick random confirmation message for succesful mission complete
		match current_planet.planetFaction:
			Utility.FACTION.FEDERATION:
				data.random_confirm = federation_thankYou.pick_random()
			Utility.FACTION.KLINGON:
				data.random_confirm = klingon_thankYou.pick_random()
			Utility.FACTION.ROMULAN:
				data.random_confirm = romulan_thankYou.pick_random()
		
		# Format UI with mission finish
		var template_text: String = "Welcome to {planet}, {ship_name}, {random_confirm}"
		var formatted_text: String = template_text.format(data)
		comms_message.bbcode_text = formatted_text
		
		SignalBus.finishMission.emit()

func _enter_comms(planet):
	current_planet = planet
	
func _exit_comms(planet):
	current_planet = null
	close_comms()
	
