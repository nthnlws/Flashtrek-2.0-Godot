extends Resource
class_name MissionData

var cargo_types: Array[String] = ["Dilithium Crystals", "Trilithium Resin", "Medical Supplies", "Phaser Components", "Food Rations", "Isolinear Chips", "Antimatter Pods", "Bioneural Gel Packs", "Quantum Torpedoes", "Romulan Ale", "Scientific Equipment", "Exotic Plants", "Cultural Artifacts", "Raw Latinum", "Terraforming Supplies", "Engineering Tools", "Warp Coils", "Diplomatic Documents", "Starfleet Uniforms", "Holodeck Matrix Components", "Rare Minerals", "Subspace Relay Components", "Vaccines", "Graviton Stabilizers", "Tritanium", "Biomimetic Gel", "Sensor Arrays", "Temporal Artifacts", "Borg Debris", "Rare Spices or Foods", "Alien Animal Specimens", "Subspace Dampeners", "Energy Shields", "Repair Drones", "Navigational Charts", "Cryogenic Pods", "Experimental Technology", "Klingon Bloodwine", "Xenobiological Samples"]
var cargo_full_messages:  Array[String] = ["[color=#f06c82]Cargo hold is already full.[/color] Return when you've delivered the goods.", "[color=#f06c82]Mission queue is full.[/color] Complete your current objectives first.", "[color=#f06c82]No room for more cargo.[/color] Clear your hold before accepting another mission.", "[color=#f06c82]You’re already assigned a mission.[/color] Finish it before taking on more.", "[color=#f06c82]Your current mission needs completion first.[/color] Come back later.", "[color=#f06c82]Ship’s storage is maxed out.[/color] Offload before taking another task.", "[color=#f06c82]No additional cargo can be loaded.[/color] Finish your delivery first.", "[color=#f06c82]One task at a time![/color] Complete your current mission before returning."]
var confirmation_accept_prompts: Array[String] = ["Will you take on this task?", "Do you agree to these terms?", "Are you ready to proceed?", "Shall we begin the mission?", "Is this assignment acceptable?", "Can we count on your assistance?", "Do you confirm your participation?"]
var confirmation_complete_prompts: Array[String] = ["Ready to complete the assignment?", "Prepared to proceed with the task.", "All systems go, proceed with beam.", "Acknowledged. Moving to final phase.", "Cargo confirmed, beam it over.", "Orders understood, ready to receive cargo.", "Initiating final mission steps."]
var federation_thankYou: Array[String] = ["Your delivery has arrived. Starfleet commends your service.", "Shipment secured. We appreciate your reliability.", "Thank you. The Federation acknowledges your efforts.", "Mission complete. Your record has been updated.", "Excellent work. Cargo confirmed and logged."]
var klingon_thankYou: Array[String] = ["The cargo is delivered. You have done honor to this task.", "Your duty is fulfilled. Qapla’!", "Well fought. The shipment has arrived intact.", "You have earned your reward in glory and goods.", "Delivery made. Strength is proven through action."]
var romulan_thankYou: Array[String] = ["Your task is complete. Efficiency is... noted.", "Delivery received. The Empire is satisfied.", "You’ve served the mission well—for now.", "Shipment secured. Your discretion is appreciated.", "Another successful operation. You may continue."]

@export var missionID: String = ""
@export var missionType: String = "Cargo Delivery"
@export var targetSystem: SystemData
@export var missionFaction: Utility.FACTION
@export var targetPlanet: String
@export var cargo: String
@export var message: String
@export var reward: int = 0


func generate_mission_offer() -> MissionData:
	var new_mission:MissionData = MissionData.new()
	# Get random system
	var random_system = LevelManager.galaxy_data.systems.pick_random()
	while random_system == LevelManager.current_system_data or random_system.system_index == 18: # Repeat pick if chose current system or missing #18 system
		random_system = LevelManager.galaxy_data.systems.pick_random()
	
	# Get random planet from picked system
	var planet_name: String = random_system.planet_data.pick_random().name
	var faction: Utility.FACTION = random_system.faction
	#print_debug(Utility.FACTION.keys()[faction])
	
	var item_name: String = cargo_types.pick_random()
	var random_confirm_query: String = confirmation_accept_prompts.pick_random()
	var mission_reward: int = GalaxyData.get_jump_distance(LevelManager.current_system_data.system_index, random_system.system_index) * 1000
	
	# UUID Generation
	var item_info: String = item_name.to_snake_case()
	var timestamp: int = Time.get_ticks_msec()
	var mission_id: String = "TASK_cargo_%s_%d" % [item_info, timestamp]
	
	missionID = mission_id
	missionType = "Cargo delivery"
	targetSystem = random_system
	targetPlanet = planet_name
	cargo = item_name
	missionFaction = faction
	message = random_confirm_query
	reward = mission_reward
	
	return self
