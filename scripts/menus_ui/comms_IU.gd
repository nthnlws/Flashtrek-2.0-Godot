extends Control

@onready var player: Player = LevelData.player
@onready var comms_message: RichTextLabel = $Comms_message

var sound_array:Array[Node] = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

var pending_mission: Dictionary
var completedUIdisplay: bool # Var to lock new mission select until menu closed after completion

var cargo_types: Array[String] = [
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

var cargo_full_messages: Array[String] = [
	"[color=#f06c82]Cargo hold is already full.[/color] Return when you've delivered the goods.",
	"[color=#f06c82]Mission queue is full.[/color] Complete your current objectives first.",
	"[color=#f06c82]No room for more cargo.[/color] Clear your hold before accepting another mission.",
	"[color=#f06c82]You’re already assigned a mission.[/color] Finish it before taking on more.",
	"[color=#f06c82]Your current mission needs completion first.[/color] Come back later.",
	"[color=#f06c82]Ship’s storage is maxed out.[/color] Offload before taking another task.",
	"[color=#f06c82]No additional cargo can be loaded.[/color] Finish your delivery first.",
	"[color=#f06c82]One task at a time![/color] Complete your current mission before returning."]

var confirmation_accept: Array[String] = [
	"Will you take on this task?",
	"Do you agree to these terms?",
	"Are you ready to proceed?",
	"Shall we begin the mission?",
	"Is this assignment acceptable?",
	"Can we count on your assistance?",
	"Do you confirm your participation?"]

var confirmation_complete: Array[String] = [
	"Ready to complete the assignment?",
	"Prepared to proceed with the task.",
	"All systems go, proceed with beam.",
	"Acknowledged. Moving to final phase.",
	"Cargo confirmed, beam it over.",
	"Orders understood, ready to receive cargo.",
	"Initiating final mission steps.",
]
var federation_thankYou: Array[String] = [
	"Your delivery has arrived. Starfleet commends your service.",
	"Shipment secured. We appreciate your reliability.",
	"Thank you. The Federation acknowledges your efforts.",
	"Mission complete. Your record has been updated.",
	"Excellent work. Cargo confirmed and logged.",]
var klingon_thankYou: Array[String] = [
	"The cargo is delivered. You have done honor to this task.",
	"Your duty is fulfilled. Qapla’!",
	"Well fought. The shipment has arrived intact.",
	"You have earned your reward in glory and goods.",
	"Delivery made. Strength is proven through action.",]
var romulan_thankYou: Array[String] = [
	"Your task is complete. Efficiency is... noted.",
	"Delivery received. The Empire is satisfied.",
	"You’ve served the mission well—for now.",
	"Shipment secured. Your discretion is appreciated.",
	"Another successful operation. You may continue.",]

var current_planet: Node2D
var ship_name: String

func _ready() -> void:
	#Signal Connections
	_connect_signals()
	
	ship_name = Utility.player_name

	# Initialize sound array
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()


func _connect_signals() -> void:
	SignalBus.enteredPlanetComm.connect(_enter_comms_range)
	SignalBus.exitedPlanetComm.connect(_exit_comms)
	SignalBus.TopRight_clicked.connect(handle_cargo_beam)
	SignalBus.BottomLeft_clicked.connect(open_comms)
	SignalBus.entering_galaxy_warp.connect(close_comms)


func update_comms_message(message: String):
	comms_message.bbcode_text = message


func _handle_reroll_pressed() -> void:
	completedUIdisplay = false
	
	SignalBus.UIclickSound.emit()
	if _can_accept_mission():
		var current_mission: Dictionary = generate_mission()
		update_comms_message(create_new_mission_text(current_mission))


func _handle_close_ui_pressed() -> void:
	$CloseButton.pressed = false
	$CloseButton.hover = false
	
	SignalBus.UIclickSound.emit()
	close_comms()


func open_comms() -> void:
	if _can_enter_comms():
		SignalBus.toggleQ3HUD.emit("off")
		self.visible = true
		if player.has_mission == false:
			var mission_data: Dictionary = generate_mission()
			update_comms_message(create_new_mission_text(mission_data))
		else:
			update_comms_message(set_mission_full_text())


func _can_enter_comms() -> bool:
	if current_planet and player.overdrive_active == false:
		return true
	else: return false


func close_comms() -> void:
	SignalBus.toggleQ2HUD.emit("off") # Turn beam HUD animation off
	completedUIdisplay = false
	visible = false
	if player.has_mission == false: # Turn on hail animation if mission still empty
		SignalBus.toggleQ3HUD.emit("on")


#region 
func generate_mission() -> Dictionary:
	# Get random system
	var system_keys: Array = Navigation.systems
	var random_system_name = system_keys.pick_random()
	while random_system_name == Navigation.currentSystem:
		random_system_name = system_keys.pick_random()
	
	# Get random planet from picked system
	var planet_list: Array = LevelData.all_systems_data[str(random_system_name)].planet_data
	var random_planet: String = str(planet_list.pick_random().name)
	
	var item_name: String = cargo_types.pick_random()
	var random_confirm_query: String = confirmation_accept.pick_random()
	var mission_reward: int = Navigation.get_system_distance(Navigation.currentSystem, random_system_name) * 1000
	
	var misson_data: Dictionary = {
		"mission_type": "Cargo delivery",
		"system": random_system_name,
		"planet": random_planet,
		"cargo": item_name,
		"message": random_confirm_query,
		"reward": mission_reward,
	}
	
	pending_mission = misson_data
	SignalBus.toggleQ2HUD.emit("on")
	return misson_data


func create_new_mission_text(mission_data: Dictionary) -> String:
	var data: Dictionary = {
		"planet": "[color=#6699CC]" + current_planet.name + "[/color]",
		"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
		"target_planet": "[color=#FFCC66]" + mission_data.planet + "[/color]",
		"target_system": "[color=#FFCC66]" + mission_data.system + "[/color]",
		"item_name": "[color=#1DCC4`B]" + mission_data.cargo + "[/color]",
		"random_confirm_query": mission_data.message,
		}
	var template_text: String = "Welcome to {planet}, {ship_name}, {target_planet} in the {target_system} system needs a shipment of {item_name}. {random_confirm_query}"
	var formatted_text: String = template_text.format(data)
	return formatted_text


func set_mission_full_text() -> String:
	var data: Dictionary = {
			"planet": "[color=#6699CC]" + current_planet.name + "[/color]",
			"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
			}
	var formatted_text:String
	
	# Current planet is ready to finish mission
	if current_planet.name == player.current_mission.planet:
		SignalBus.toggleQ2HUD.emit("on") # Turn beam HUD animation on
		data.random_accept = confirmation_complete.pick_random()
		var template_text: String = "Welcome to {planet}, {ship_name}, {random_accept}"
		formatted_text = template_text.format(data)
		
	# Wrong planet for mission
	else:
		SignalBus.toggleQ2HUD.emit("off")
		data.random_deny = cargo_full_messages.pick_random()
			
		var template_text: String = "Welcome to {planet}, {ship_name}, {random_deny}"
		formatted_text = template_text.format(data)
	
	return formatted_text


func _can_accept_mission() -> bool:
	if pending_mission and visible and player.has_mission == false and completedUIdisplay == false:
		return true
	else: return false

func _can_complete_mission() -> bool:
	if visible and player.has_mission and current_planet.name == player.current_mission.planet:
		return true
	else: return false


func handle_cargo_beam() -> void:
	# Accept new mission
	SignalBus.toggleQ2HUD.emit("off") # Turn off "Beam" HUD animation
	if _can_accept_mission():
		pick_up_new_mission()
	
	elif _can_complete_mission():
		finish_mission()


func pick_up_new_mission() -> void:
	# Update text to "accepted"
	var data: Dictionary = {
		"target_planet": "[color=#FFCC66]" + pending_mission.planet + "[/color]",
		"target_system": "[color=#FFCC66]" + pending_mission.system + "[/color]",
		}
		
		
	var template_text: String = "Mission accepted! Head to {target_planet} in the {target_system} system."
	var formatted_text: String = template_text.format(data)

	update_comms_message(formatted_text)
	SignalBus.missionAccepted.emit(pending_mission)


func finish_mission() -> void:
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
	update_comms_message(formatted_text)
	
	SignalBus.finishMission.emit()


func _enter_comms_range(planet) -> void:
	current_planet = planet


func _exit_comms(planet) -> void:
	current_planet = null
	close_comms()
