class_name MissionGenerator
extends RefCounted

# --- Configuration & Weights ---
# Adjust these integers to change the rarity of missions
const TYPE_WEIGHTS: Dictionary = {
	MissionData.MISSION_TYPE.DELIVERY: 30,
	MissionData.MISSION_TYPE.CONTAINER: 10,
	MissionData.MISSION_TYPE.KILL_FACTION: 12,
	MissionData.MISSION_TYPE.ESCORT: 7,
	MissionData.MISSION_TYPE.ANALYZE: 8,
	MissionData.MISSION_TYPE.SALVAGE: 8,
	MissionData.MISSION_TYPE.RESCUE: 6,
	MissionData.MISSION_TYPE.BOUNTY: 5,
	MissionData.MISSION_TYPE.SENSOR_SWEEP: 6,
	MissionData.MISSION_TYPE.DEFENSE: 4,
	MissionData.MISSION_TYPE.CONTRABAND: 4,
}

## Chance a delivery gets a follow-up rescue.
const FOLLOW_UP_CHANCE: float = 0.3

## Reward = jumps * randi_range(MIN, MAX) * destination system_difficulty_mult.
const REWARD_PER_JUMP_MIN: int = 300
const REWARD_PER_JUMP_MAX: int = 500

## Pass as max_range for no warp-range limit.
const UNLIMITED_RANGE: int = -1

const CONTRABAND_TYPES: Array[String] = [
	"Unlicensed Cloaking Components", "Tal Shiar Data Cores", "Stolen Isolinear Chips",
	"Unregistered Trilithium", "Smuggled Romulan Ale", "Black-Market Phaser Rifles",
	"Forged Transit Codes", "Undeclared Latinum Bars",
]

const BOUNTY_NAMES: Array[String] = [
	"The Red Talon", "Captain Vorak", "The Void Jackal", "Commander T'Rel",
	"The Kessel Wraith", "Warlord Kargath", "The Silent Blade", "Raider Queen Soleth",
]

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
const PROMPTS: Array[String] = [
	"Will you take on this task?", "Do you agree to these terms?", "Is this assignment acceptable?",
	"Are you ready to proceed?", "Do you confirm your participation?"
]

# --- Main Generation Function ---
## `max_range`: player's warp range in jumps; targets are limited to it
## (except Contraband). UNLIMITED_RANGE disables the limit.
static func generate_mission(current_system: SystemData, galaxy_data: GalaxyData, random: bool = true, type: MissionData.MISSION_TYPE = MissionData.MISSION_TYPE.ANALYZE, max_range: int = UNLIMITED_RANGE) -> MissionData:
	var selected_type: MissionData.MISSION_TYPE = type
	if random:
		selected_type = _pick_weighted_type()

	var mission: MissionData = MissionData.new()
	mission.type = selected_type
	mission.confirm_message = PROMPTS.pick_random()
	mission.faction_owner = current_system.faction # Default to system owner
	mission.accepted_time = Time.get_ticks_msec()
	mission.mission_id = "MSN_%d_%d_%d" % [selected_type, mission.accepted_time, randi()]
	mission.target_system = _pick_target_system(current_system, galaxy_data, max_range)

	# Branch logic based on type
	match selected_type:
		MissionData.MISSION_TYPE.DELIVERY:
			setup_delivery(mission, current_system, galaxy_data)
		MissionData.MISSION_TYPE.CONTAINER:
			setup_container(mission)
		MissionData.MISSION_TYPE.KILL_FACTION:
			setup_kill_faction(mission, current_system)
		MissionData.MISSION_TYPE.ESCORT:
			setup_escort(mission)
		MissionData.MISSION_TYPE.ANALYZE:
			setup_analysis(mission)
		MissionData.MISSION_TYPE.SALVAGE:
			setup_salvage(mission)
		MissionData.MISSION_TYPE.RESCUE:
			setup_rescue(mission)
		MissionData.MISSION_TYPE.BOUNTY:
			setup_bounty(mission, current_system)
		MissionData.MISSION_TYPE.SENSOR_SWEEP:
			setup_sensor_sweep(mission)
		MissionData.MISSION_TYPE.DEFENSE:
			setup_defense(mission, current_system, galaxy_data, max_range)
		MissionData.MISSION_TYPE.CONTRABAND:
			setup_contraband(mission, current_system, galaxy_data)

	mission.reward = calculate_reward(current_system, mission.target_system)
	return mission


## Systems other than `current_system` and Risa that are reachable within
## `max_range` jumps (any reachable distance for UNLIMITED_RANGE).
static func get_systems_in_range(current_system: SystemData, galaxy_data: GalaxyData, max_range: int) -> Array[SystemData]:
	var result: Array[SystemData] = []
	for system: SystemData in galaxy_data.systems:
		if system == current_system or system.system_index == GalaxyData.SPECIAL_SYSTEMS.Risa:
			continue
		var dist: int = GalaxyData.get_jump_distance(current_system.system_index, system.system_index)
		if dist < 1:
			continue # unreachable
		if max_range != UNLIMITED_RANGE and dist > max_range:
			continue
		result.append(system)
	return result


## In-range systems owned by `faction`.
static func get_faction_systems_in_range(current_system: SystemData, galaxy_data: GalaxyData, max_range: int, faction: Utility.FACTION) -> Array[SystemData]:
	return get_systems_in_range(current_system, galaxy_data, max_range).filter(
		func(system: SystemData) -> bool: return system.faction == faction)


## Random in-range target. Prefers systems passing `filter` when any exist,
## otherwise any in-range system.
static func _pick_target_system(current_system: SystemData, galaxy_data: GalaxyData, max_range: int, filter: Callable = Callable()) -> SystemData:
	var candidates: Array[SystemData] = get_systems_in_range(current_system, galaxy_data, max_range)
	if candidates.is_empty():
		push_warning("No mission targets within %d jumps of %s; ignoring range" % [max_range, current_system.system_name])
		candidates = get_systems_in_range(current_system, galaxy_data, UNLIMITED_RANGE)

	if filter.is_valid():
		var filtered: Array = candidates.filter(filter)
		if not filtered.is_empty():
			return filtered.pick_random()
	return candidates.pick_random()


## Enemy of `faction`; random major faction for NEUTRAL.
static func _hostile_faction_for(faction: Utility.FACTION) -> Utility.FACTION:
	if faction == Utility.FACTION.NEUTRAL:
		var aggressors: Array[Utility.FACTION] = [Utility.FACTION.FEDERATION, Utility.FACTION.KLINGON, Utility.FACTION.ROMULAN]
		return aggressors.pick_random()
	return Utility.get_enemy_faction(faction)


static func _faction_color(faction: Utility.FACTION) -> String:
	match faction:
		Utility.FACTION.FEDERATION: return Utility.fed_blue
		Utility.FACTION.KLINGON: return Utility.klin_red
		Utility.FACTION.ROMULAN: return Utility.rom_green
		_: return Utility.UI_yellow


static func _format_faction(faction: Utility.FACTION) -> String:
	var faction_name: String = Utility.FACTION.keys()[faction].to_pascal_case()
	return Utility.color_string(_faction_color(faction), faction_name)


static func _format_system(system: SystemData) -> String:
	return Utility.color_string(Utility.UI_blue, system.system_name)


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
static func setup_delivery(m: MissionData, _current_sys: SystemData, galaxy_data: GalaxyData) -> void:
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

	if randf() < FOLLOW_UP_CHANCE:
		m.follow_up = _create_follow_up_rescue(m, galaxy_data)


## Payout for flying from `origin` to `destination`. Distance is at least 1
## so a fallback target can never pay 0.
static func calculate_reward(origin: SystemData, destination: SystemData) -> int:
	var dist: int = maxi(GalaxyData.get_jump_distance(origin.system_index, destination.system_index), 1)
	var per_jump: int = randi_range(REWARD_PER_JUMP_MIN, REWARD_PER_JUMP_MAX)
	return roundi(dist * per_jump * destination.system_difficulty_mult)


static func _create_follow_up_rescue(parent: MissionData, galaxy_data: GalaxyData) -> MissionData:
	var follow_up: MissionData = MissionData.new()
	follow_up.type = MissionData.MISSION_TYPE.RESCUE
	follow_up.faction_owner = parent.faction_owner
	follow_up.accepted_time = Time.get_ticks_msec()
	follow_up.mission_id = "MSN_%d_%d_%d" % [follow_up.type, follow_up.accepted_time, randi()]

	# Rescue takes place in a neighbour of the delivery target
	var neighbors: Array[SystemData] = []
	for neighbor_id: int in parent.target_system.neighbor_ids:
		var neighbor: SystemData = galaxy_data.get_system(neighbor_id)
		if neighbor and neighbor.system_index != GalaxyData.SPECIAL_SYSTEMS.Risa:
			neighbors.append(neighbor)
	follow_up.target_system = neighbors.pick_random() if not neighbors.is_empty() else parent.target_system

	setup_rescue(follow_up)
	follow_up.reward = calculate_reward(parent.target_system, follow_up.target_system)
	follow_up.title = "Convoy Recovery"
	follow_up.description = "the convoy that collected your %s was ambushed in the %s system. Tow its disabled freighter back to the starbase" % [
		Utility.color_string(Utility.UI_yellow, parent.cargo), _format_system(follow_up.target_system)
	]
	return follow_up


static func setup_kill_faction(m: MissionData, current_system: SystemData) -> void:
	m.title = "Sector Patrol"
	m.enemy_faction = Utility.get_enemy_faction(m.faction_owner)
	m.enemy_target_count = randi_range(2, 5)
	
	var formatted_system: String = Utility.color_string(Utility.UI_blue, m.target_system.system_name)
	
	# Format faction
	var faction: String = Utility.FACTION.keys()[m.enemy_faction]
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
	
	m.description = "patrol the %s system and eliminate %s %s ships" % [
		formatted_system,
		formatted_kills,
		formatted_faction,
	]

static func setup_container(m: MissionData) -> void:
	m.title = "Container"
	m.cargo = CARGO_TYPES.pick_random()
	var formatted_cargo: String = Utility.color_string(Utility.UI_yellow, m.cargo)
	var formatted_system: String = Utility.color_string(Utility.UI_blue, m.target_system.system_name)
	m.container_target = ContainerData.create_container_data(m.cargo, m.faction_owner, UUID.generate_UUID())
	m.description = "scanners detected a %s container drifting in the %s system. Retrieve it" % [
		formatted_cargo, formatted_system
	]

static func setup_escort(m: MissionData) -> void:
	m.title = "VIP Transport"
	m.enemy_faction = _hostile_faction_for(m.faction_owner)
	m.description = "escort a high-value transport through the %s system. Expect %s resistance" % [
		_format_system(m.target_system), _format_faction(m.enemy_faction)
	]

static func setup_analysis(m: MissionData) -> void:
	m.title = "Scientific Survey"
	m.target_planet_name = m.target_system.planet_data.pick_random().name
	var formatted_planet: String = Utility.color_string(Utility.UI_yellow, m.target_planet_name)
	var formatted_system: String = Utility.color_string(Utility.UI_blue, m.target_system.system_name)
	m.description = "orbit %s in the %s system and perform a full planetary scan" % [
		formatted_planet, formatted_system
	]


static func setup_salvage(m: MissionData) -> void:
	m.title = "Salvage Operation"
	m.description = "a debris field in the %s system holds recoverable components. Use your tractor beam to haul in the marked salvage" % _format_system(m.target_system)


static func setup_rescue(m: MissionData) -> void:
	m.title = "Distress Call"
	m.enemy_faction = _hostile_faction_for(m.faction_owner)
	m.description = "a disabled ship is drifting in the %s system under %s attack. Tow it back to the starbase with your tractor beam" % [
		_format_system(m.target_system), _format_faction(m.enemy_faction)
	]


static func setup_bounty(m: MissionData, _current_system: SystemData) -> void:
	m.title = "Bounty Hunt"
	m.enemy_faction = _hostile_faction_for(m.faction_owner)
	m.bounty_name = BOUNTY_NAMES.pick_random()
	var formatted_target: String = Utility.color_string(_faction_color(m.enemy_faction), m.bounty_name)
	m.description = "the %s ship %s was last sighted in the %s system. Hunt it down before it moves on" % [
		_format_faction(m.enemy_faction), formatted_target, _format_system(m.target_system)
	]


static func setup_sensor_sweep(m: MissionData) -> void:
	m.title = "Sensor Sweep"
	m.description = "calibrate the sensor buoys scattered across the %s system before the survey window closes" % _format_system(m.target_system)


## Defends an in-range starbase of the pickup system's faction. Every
## faction system has a same-faction neighbour; Risa (neutral) has none and
## falls back to any in-range system.
static func setup_defense(m: MissionData, current_system: SystemData, galaxy_data: GalaxyData, max_range: int) -> void:
	m.title = "Starbase Defense"
	var same_faction: Array[SystemData] = get_faction_systems_in_range(current_system, galaxy_data, max_range, current_system.faction)
	if same_faction.is_empty():
		m.target_system = _pick_target_system(current_system, galaxy_data, max_range)
	else:
		m.target_system = same_faction.pick_random()
	m.enemy_faction = _hostile_faction_for(m.target_system.faction)
	m.description = "%s forces are massing to strike the starbase in the %s system. Hold them off" % [
		_format_faction(m.enemy_faction), _format_system(m.target_system)
	]


static func setup_contraband(m: MissionData, current_system: SystemData, galaxy_data: GalaxyData) -> void:
	m.title = "Discreet Delivery"
	m.cargo = CONTRABAND_TYPES.pick_random()
	m.scanning_faction = _hostile_faction_for(m.faction_owner)
	var scanner: Utility.FACTION = m.scanning_faction
	# Deliberately ignores warp range: may require several warps.
	m.target_system = _pick_target_system(current_system, galaxy_data, UNLIMITED_RANGE, func(system: SystemData) -> bool: return system.faction == scanner)
	m.target_planet_name = m.target_system.planet_data.pick_random().name

	m.description = "we need %s delivered to %s in the %s system. Avoid lingering near %s patrols - if they scan your hold, they will open fire" % [
		Utility.color_string(Utility.UI_yellow, m.cargo),
		Utility.color_string(Utility.UI_blue, m.target_planet_name),
		_format_system(m.target_system),
		_format_faction(m.scanning_faction),
	]
