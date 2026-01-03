extends Node2D
class_name Planet

# --- NODES ---
@onready var node: Node2D = $Node
@onready var label: RichTextLabel = $Node/Label
@onready var sprite: Sprite2D = $PlanetTexture

# --- STATE ---
var planetFaction: Utility.FACTION = Utility.FACTION.FEDERATION
var CanCommunicate: bool = false
var player: Player

func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(fade_label.bind("off"))
	SignalBus.entering_new_system.connect(fade_label.bind("on"))
	
	var random_index: int = randi_range(0, 220)
	sprite.frame = random_index
	z_index = Utility.Z["Planets"]

func _physics_process(delta: float) -> void:
	rotate(deg_to_rad(1.5) * delta)
	node.global_rotation = 0 # Counter rotate label

# --- INTERACTION LOGIC (New) ---

## Called by CommsUI when opening the menu. Returns the greeting/mission text.
func request_hail(player_ship_name: String) -> String:
	
	# 1. Active Mission Logic
	if MissionManager.current_state == MissionManager.STATE.active_mission:
		if MissionManager.active_mission.target_planet_name == self.name:
			# We are the destination
			return MissionGenerator.confirmation_complete_prompts.pick_random()
		else:
			# We are not the destination, and player has cargo
			return MissionGenerator.cargo_full_messages.pick_random()
	
	# 2. No Mission / Pending Logic
	if (MissionManager.current_state == MissionManager.STATE.no_mission 
		or MissionManager.current_state == MissionManager.STATE.pending_mission):
		
		# If we don't have a pending mission yet, or we are rerolling, generate one
		# (Logic assumes we want to refresh if the UI calls this in pending state)
		MissionManager.generate_mission()
		return _format_mission_offer(MissionManager.pending_mission, player_ship_name)

	return "Channel open. No data available."

## Called by CommsUI when the action button (Beam/Accept) is pressed.
func attempt_interaction(player_ship_name: String) -> String:
	
	# A. Accept Pending
	if MissionManager.current_state == MissionManager.STATE.pending_mission:
		MissionManager.accept_pending_mission()
		var mission: MissionData = MissionManager.active_mission
		
		MissionManager.mission_started.emit(mission)
		
		var formatted_system: String = _get_faction_color_string(mission.target_system.faction, mission.target_system.system_name)
		
		return "Mission accepted! Head to the %s system." % formatted_system

	# B. Complete Active
	elif (MissionManager.current_state == MissionManager.STATE.active_mission 
		and MissionManager.active_mission.target_planet_name == self.name):
		
		var completed_mission: MissionData = MissionManager.active_mission
		MissionManager.complete_mission()
		return _format_completion_message(completed_mission, player_ship_name)
		
	return ""


# --- FORMATTING HELPERS (Private) ---
func _format_mission_offer(mission: MissionData, ship_name: String) -> String:
	var data: Dictionary = {
		"planet": "[color=#FFCC66]" + self.name + "[/color]",
		"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
		"target_planet": "[color=#FFCC66]" + mission.target_planet_name + "[/color]",
		"target_system": _get_faction_color_string(mission.target_system.faction, mission.target_system.system_name),
		"item_name": "[color=#1DCC4B]" + mission.cargo + "[/color]",
		"random_confirm_query": mission.confirm_message,
		"mission_description": mission.description
	}
	
	var template: String = "Welcome to {planet}, {ship_name}, {mission_description}. {random_confirm_query}"
	return template.format(data)


func _format_completion_message(mission: MissionData, ship_name: String) -> String:
	var data: Dictionary = {
		"planet": "[color=#6699CC]" + mission.target_planet_name + "[/color]",
		"ship_name": "[color=#3bdb8b]" + ship_name + "[/color]",
		"random_confirm": ""
	}
	
	# Pick thank you message based on this planet's faction
	match self.planetFaction:
		Utility.FACTION.FEDERATION:
			data.random_confirm = MissionGenerator.federation_thankYou.pick_random()
		Utility.FACTION.KLINGON:
			data.random_confirm = MissionGenerator.klingon_thankYou.pick_random()
		Utility.FACTION.ROMULAN:
			data.random_confirm = MissionGenerator.romulan_thankYou.pick_random()
		_:
			data.random_confirm = "Transaction complete."
	
	return "Welcome to {planet}, {ship_name}, {random_confirm}".format(data)


func _get_faction_color_string(faction: int, text: String) -> String:
	var color_code: String = Utility.UI_yellow # Default
	match faction:
		Utility.FACTION.FEDERATION: color_code = Utility.fed_blue
		Utility.FACTION.ROMULAN:    color_code = Utility.rom_green
		Utility.FACTION.KLINGON:    color_code = Utility.klin_red
	
	return color_code + text + "[/color]"

# --- VISUALS & SIGNALS ---

func _on_comm_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.enteredPlanetComm.emit(self)
		SignalBus.toggleQ3HUD.emit("on")
		player = body


func _on_comm_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.exitedPlanetComm.emit(self)
		SignalBus.toggleQ3HUD.emit("off")
		player = null


func set_frame(index: int) -> void:
	sprite.frame = index


func set_label(planet_name: String) -> void:
	self.name = planet_name # Ensure node name matches
	label.text = Utility.UI_blue + planet_name # 'text' handles bbcode if enabled


func fade_label(state: String) -> void:
	if state == "off":
		create_tween().tween_property(label, "modulate", Color(1, 1, 1, 0), Utility.fadeLength)
	elif state == "on":
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(label, "modulate", Color(1, 1, 1, 1), Utility.fadeLength)
