class_name MissionGenerator
extends RefCounted

# --- Configuration & Weights ---
# Adjust these integers to change the rarity of missions
const TYPE_WEIGHTS: Dictionary = {
	MissionData.MISSION_TYPE.DELIVERY: 50, # 50% chance
	MissionData.MISSION_TYPE.CONTAINER: 15, # 15% chance
	MissionData.MISSION_TYPE.KILL_FACTION: 20, # 20% chance
	MissionData.MISSION_TYPE.ESCORT: 5, # 5% chance
	MissionData.MISSION_TYPE.ANALYZE: 10, # 10% chance
}

const CARGO_TYPES: Array[String] = [
	"Dilithium Crystals", "Trilithium Resin", "Medical Supplies",
	"Phaser Components", "Food Rations", "Isolinear Chips", "Antimatter Pods",
	"Bioneural Gel Packs", "Quantum Torpedoes", "Romulan Ale", "Scientific Equipment",
	"Exotic Plants", "Cultural Artifacts", "Raw Latinum", "Terraforming Supplies",
	"Engineering Tools", "Warp Coils", "Diplomatic Documents", "Starfleet Uniforms",
	"Holodeck Matrix Components", "Rare Minerals", "Subspace Relay Components",
	"Vaccines", "Graviton Stabilizers", "Tritanium", "Biomimetic Gel", "Sensor Arrays",
	"Temporal Artifacts", "Borg Debris", "Rare Spices or Foods", "Alien Animal Specimens", "
	Subspace Dampeners", "Energy Shields", "Repair Drones", "Navigational Charts",
	"Cryogenic Pods", "Experimental Technology", "Klingon Bloodwine", "Xenobiological Samples"
	]

static var cargo_full_messages: Array[String] = [
	"[color=#f06c82]Cargo hold is already full.[/color] Return when you've delivered the goods.",
	"[color=#f06c82]Mission queue is full.[/color] Complete your current objectives first.",
	"[color=#f06c82]No room for more cargo.[/color] Clear your hold before accepting another mission.",
	"[color=#f06c82]You’re already assigned a mission.[/color] Finish it before taking on more.",
	"[color=#f06c82]Your current mission needs completion first.[/color] Come back later.",
	"[color=#f06c82]Ship’s storage is maxed out.[/color] Offload before taking another task.",
	"[color=#f06c82]No additional cargo can be loaded.[/color] Finish your delivery first.",
	"[color=#f06c82]One task at a time![/color] Complete your current mission before returning.",
	"[color=#f06c82]Insufficient cargo space.[/color] We cannot load these supplies until you make room.",
	"[color=#f06c82]Logistics error.[/color] The quartermaster reports your hold is at maximum capacity."
]
static var confirmation_accept_prompts: Array[String] = [
	"Will you take on this task?", "Do you agree to these terms?", "Are you ready to proceed?",
	"Shall we begin the mission?", "Is this assignment acceptable?", "Can we count on your assistance?",
	"Do you confirm your participation?", "Stand by for mission parameters. Do you accept?",
	"We need a reliable captain for this. Are you in?", "Awaiting your confirmation to authorize launch.",
	"This is a priority request. Can you handle the assignment?"
]
static var confirmation_complete_prompts: Array[String] = [
	"Ready to complete the assignment?", "Prepared to proceed with the task.",
	"All systems go, proceed with beam.", "Acknowledged. Moving to final phase.",
	"Cargo confirmed, beam it over.", "Orders understood, ready to receive cargo.",
	"Initiating final mission steps.", "We're standing by to receive your manifest.",
	"Transporters locked. Ready when you are, Captain.", "Please confirm final objective completion."
]
static var federation_thankYou: Array[String] = [
	"Your delivery has arrived. Starfleet commends your service.", "Shipment secured. We appreciate your reliability.",
	"Thank you. The Federation acknowledges your efforts.", "Mission complete. Your record has been updated.",
	"Excellent work. Cargo confirmed and logged.", "Live long and prosper. The supplies are safe.",
	"Starfleet Command sends their regards for a job well done.", "Your assistance has been invaluable to our sector."
]
static var klingon_thankYou: Array[String] = [
	"The cargo is delivered. You have done honor to this task.", "Your duty is fulfilled. Qapla’!",
	"Well fought. The shipment has arrived intact.", "You have earned your reward in glory and goods.",
	"Delivery made. Strength is proven through action.", "Today is a good day to deliver! Qapla’!",
	"The High Council acknowledges your worth.", "A warrior's task, completed with honor."
]
static var romulan_thankYou: Array[String] = [
	"Your task is complete. Your efficiency has been noted.", "Delivery received. The Empire is satisfied.",
	"You’ve served the mission well—for now.", "Shipment secured. Your discretion is appreciated.",
	"Another successful operation. You may continue.", "The Tal Shiar commends your silence on this matter.",
	"Do not let success breed arrogance. The Praetor thanks you.", "A profitable exchange. Jolan tru."
]
const PROMPTS: Array[String] = [
	"Will you take on this task?", "Do you agree to these terms?", "Is this assignment acceptable?",
	"Are you ready to proceed?", "Do you confirm your participation?"
]

# --- Main Generation Function ---
static func generate_mission(current_system: SystemData, galaxy_data: GalaxyData, random: bool = true, type: MissionData.MISSION_TYPE = MissionData.MISSION_TYPE.ANALYZE) -> MissionData:
	var selected_type: MissionData.MISSION_TYPE = type
	if random:
		selected_type = _pick_weighted_type()
	
	# Pick a random target system (logic from your original script)
	var target_system: SystemData = galaxy_data.systems.pick_random()
	while target_system == current_system or target_system.system_index == GalaxyData.SPECIAL_SYSTEMS.Risa:
		target_system = galaxy_data.systems.pick_random()
	
	var mission: MissionData = MissionData.new()
	mission.type = selected_type
	mission.confirm_message = PROMPTS.pick_random()
	mission.target_system = target_system
	mission.faction_owner = target_system.faction # Default to system owner
	mission.accepted_time = Time.get_ticks_msec()
	mission.mission_id = "MSN_%d_%d" % [selected_type, mission.accepted_time]
	
	# Branch logic based on type
	match selected_type:
		MissionData.MISSION_TYPE.DELIVERY:
			_setup_delivery(mission, current_system)
		MissionData.MISSION_TYPE.CONTAINER:
			_setup_container(mission)
		MissionData.MISSION_TYPE.KILL_FACTION:
			_setup_kill_faction(mission, current_system)
		MissionData.MISSION_TYPE.ESCORT:
			_setup_escort(mission)
		MissionData.MISSION_TYPE.ANALYZE:
			_setup_analysis(mission)
			
	return mission

# --- Helper Logic ---
static func _pick_weighted_type() -> MissionData.MISSION_TYPE:
	var total_weight: int = 0
	for w in TYPE_WEIGHTS.values():
		total_weight += w
	
	var roll: int = randi() % total_weight
	var current: int = 0
	
	for type in TYPE_WEIGHTS:
		current += TYPE_WEIGHTS[type]
		if roll < current:
			return type
	
	printerr("No weight returned for mission type creation, defaulting to Delivery mission type")
	return MissionData.MISSION_TYPE.DELIVERY # Fallback


# --- Specific Setup Functions ---
static func _setup_delivery(m: MissionData, current_sys: SystemData) -> void:
	m.title = "Cargo Delivery"
	m.cargo = CARGO_TYPES.pick_random()
	var formatted_cargo: String = Utility.color_string(Utility.UI_yellow, m.cargo)
	
	# Format faction
	var faction: String = Utility.FACTION.keys()[m.faction_owner]
	var formatted_faction: String = faction.to_pascal_case()
	if formatted_faction == "Klingon":
		formatted_faction = Utility.color_string(Utility.klin_red, "Klingons")
	elif formatted_faction == "Romulan":
		formatted_faction = Utility.color_string(Utility.rom_green, "Romulans")
	elif formatted_faction == "Federation":
		formatted_faction = Utility.color_string(Utility.fed_blue, "Federation")
	
	m.target_planet_name = m.target_system.planet_data.pick_random().name
	var formatted_planet: String = Utility.color_string(Utility.UI_blue, m.target_planet_name)
	var formatted_system: String = Utility.color_string(Utility.UI_yellow, m.target_system.system_name)
	
	# Calculate Reward
	var dist = GalaxyData.get_jump_distance(current_sys.system_index, m.target_system.system_index)
	m.reward = dist * 1000
	
	if m.faction_owner == Utility.FACTION.FEDERATION: # String formatting for faction descriptions
		m.description = "The %s requires %s delivered to %s in the %s system" % [
		formatted_faction,
		formatted_cargo,
		formatted_planet,
		formatted_system,
	]
	else:
		m.description = "The %s require %s delivered to %s in the %s system" % [
		formatted_faction,
		formatted_cargo,
		formatted_planet,
		formatted_system,
	]
	

static func _setup_kill_faction(m: MissionData, current_system: SystemData) -> void:
	m.title = "Sector Patrol"
	m.enemy_faction = Utility.get_enemy_faction(m.faction_owner)
	m.enemy_target_count = randi_range(2, 5)
	
	# Ensure that faction for mission is not the same faction as current system
	while m.faction_owner == current_system.faction:
		m.faction_owner = Utility.FACTION.keys().pick_random()
	
	var formatted_system: String = Utility.color_string(Utility.UI_blue, m.target_system.system_name)
	
	# Format faction
	var faction: String = Utility.FACTION.keys()[m.faction_owner]
	var formatted_faction: String = faction.to_pascal_case()
	var formatted_kills: String
	if formatted_faction == "Klingon":
		formatted_faction = Utility.color_string(Utility.klin_red, "Klingon")
		formatted_kills = Utility.color_string(Utility.klin_red, str(m.enemy_target_count))
	elif formatted_faction == "Romulan":
		formatted_faction = Utility.color_string(Utility.rom_green, "Romulan")
		formatted_kills = Utility.color_string(Utility.rom_green, str(m.enemy_target_count))
	elif formatted_faction == "Federation":
		formatted_faction = Utility.color_string(Utility.fed_blue, "Federation")
		formatted_kills = Utility.color_string(Utility.fed_blue, str(m.enemy_target_count))
	
	m.reward = m.enemy_target_count * 500
	m.description = "patrol the %s system and eliminate %s %s ships" % [
		formatted_system,
		formatted_kills,
		formatted_faction,
	]

static func _setup_container(m: MissionData) -> void:
	m.title = "Container"
	m.cargo = CARGO_TYPES.pick_random()
	var formatted_cargo: String = Utility.color_string(Utility.UI_yellow, m.cargo)
	var formatted_system: String = Utility.color_string(Utility.UI_blue, m.target_system.system_name)
	m.container_target = ContainerData.create_container_data(m.cargo, m.faction_owner)
	m.reward = randi_range(500, 2000)
	m.description = "scanners detected a %s container drifting in the %s system. Retrieve it" % [
		formatted_cargo, formatted_system
	]

static func _setup_escort(m: MissionData) -> void:
	m.title = "VIP Transport"
	var formatted_system: String = Utility.color_string(Utility.UI_blue, m.target_system.system_name)
	m.description = "escort a high-value transport to %s. Expect resistance" % formatted_system
	m.reward = 5000

static func _setup_analysis(m: MissionData) -> void:
	m.title = "Scientific Survey"
	m.target_planet_name = m.target_system.planet_data.pick_random().name
	var formatted_planet: String = Utility.color_string(Utility.UI_yellow, m.target_planet_name)
	var formatted_system: String = Utility.color_string(Utility.UI_blue, m.target_system.system_name)
	m.description = "orbit %s in the %s system and perform a full planetary scan" % [
		formatted_planet, formatted_system
	]
	m.reward = 2500
