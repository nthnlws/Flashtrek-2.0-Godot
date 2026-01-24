extends Node2D
class_name Planet

@onready var label: RichTextLabel = $Label
@onready var sprite: Sprite2D = $PlanetTexture
@onready var mission_indicator: Node2D = $MissionIndicator

var planetFaction: Utility.FACTION = Utility.FACTION.FEDERATION
var CanCommunicate: bool = false
var player: Player
var player_in_mission_area: bool = false


func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(fade_label.bind("off"))
	SignalBus.entering_new_system.connect(fade_label.bind("on"))
	mission_indicator.player_entered.connect(_handle_player_in_mission_area)
	
	create_analyis_point()
	queue_redraw() # Debug drawing for 
	
	var random_index: int = randi_range(0, 220)
	sprite.frame = random_index
	z_index = Utility.Z["Planets"]

func _physics_process(delta: float) -> void:
	sprite.rotate(deg_to_rad(1.5) * delta) # Spin planet

#region Player Comms
# --- INTERACTION LOGIC  ---

# Called by CommsUI when opening the menu. Returns the greeting/mission text.
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

# Called by CommsUI when the action button (Beam/Accept) is pressed.
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

#endregion


#region Visuals
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
#endregion

#region Mission Cutscene Sequences
signal sequence_started
signal sequence_finished

func create_analyis_point() -> void:
	var mission_point:Vector2 = Utility.get_random_point_on_circle(1500.0)
	mission_indicator.activate_indicator(mission_point)

func _handle_player_in_mission_area(player: Node2D) -> void:
	if !player.overdrive_active:
		mission_indicator.deactivate_indicator()

# Configuration
@export var orbit_radius: float = 1500.0
@export var approach_duration: float = 1.5
@export var max_orbit_speed: float = 800.0
@export var orbit_color: Color = Color(0.2, 0.8, 1.0, 0.5)
var accel_fraction: float = 0.15 

# Internal State
var _target_player: Node2D = null
var _is_active: bool = false
var _orbit_start_angle: float = 0.0

# Input handling for testing
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("F9") and LevelManager.player:
		start_orbit_sequence(LevelManager.player)

func _draw() -> void:
	if Engine.is_editor_hint() or _is_active:
		draw_arc(Vector2.ZERO, orbit_radius, 0, TAU, 64, orbit_color, 2.0)

# Call this to start the cutscene
var previous_gamestate:int
func start_orbit_sequence(player: Node2D) -> void:
	if _is_active: return
	
	_is_active = true
	_target_player = player
	sequence_started.emit()
	queue_redraw()

	# 1. Disable Player
	if _target_player.has_method("set_physics_process"):
		_target_player.set_physics_process(false)
		if "velocity" in _target_player:
			_target_player.velocity = Vector2.ZERO

	# 2. Calculate Geometry
	var vector_to_player: Vector2 = _target_player.global_position - global_position
	_orbit_start_angle = vector_to_player.angle()
	
	# Entry point on the circle
	var entry_pos: Vector2 = global_position + Vector2(cos(_orbit_start_angle), sin(_orbit_start_angle)) * orbit_radius
	
	# Target rotation (Tangent)
	var target_rot: float = _orbit_start_angle + (PI / 2.0)
	var current_rot: float = _target_player.rotation
	# Smallest rotation path to avoid spinning 360
	var final_rot_value: float = current_rot + angle_difference(current_rot, target_rot)

	# 3. Calculate Duration
	# Circumference = 2 * PI * r
	var path_length: float = TAU * orbit_radius
	# Adjust duration because we spend some time accelerating.
	# Formula: Time = Distance / (Speed * (1 - accel_fraction))
	var duration: float = path_length / (max(max_orbit_speed, 1.0) * (1.0 - accel_fraction))

	# 4. Tween Sequence
	var tween: Tween = create_tween()
	
	# PHASE A: Approach (Standard Ease In/Out)
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_target_player, "global_position", entry_pos, approach_duration)
	tween.tween_property(_target_player, "rotation", final_rot_value, approach_duration)
	
	# PHASE B: Orbit (Linear Tween drive, Manual Curve math)
	tween.chain().tween_method(_process_custom_orbit, 0.0, 1.0, duration)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)

	tween.finished.connect(_on_sequence_complete)

# Runs every frame of the orbit
func _process_custom_orbit(t: float) -> void:
	if not is_instance_valid(_target_player): return

	# 1. Apply Trapezoidal Ease (Accel -> Constant -> Decel)
	var curved_t: float = _get_trapezoidal_progress(t, accel_fraction)

	# 2. Calculate Angle based on smoothed t
	var current_angle: float = lerp(_orbit_start_angle, _orbit_start_angle + TAU, curved_t)

	# 3. Update Position
	var offset: Vector2 = Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
	_target_player.global_position = global_position + offset

	# 4. Update Rotation (Always Tangent)
	_target_player.rotation = current_angle + (PI / 2.0)

# The Math Magic: Converts Linear T into Accel-Cruise-Decel T
func _get_trapezoidal_progress(t: float, a: float) -> float:
	# a = fraction of time spent accelerating (e.g. 0.15)
	if a <= 0.0: return t # Safety
	
	# Calculate the slope (velocity) needed to traverse distance 1.0 in time 1.0
	# Area under velocity curve must equal 1.
	# Area = (1 * Vmax) - (a * Vmax) -> Vmax = 1 / (1 - a)
	var v_max: float = 1.0 / (1.0 - a)
	
	if t < a:
		# Acceleration phase (Quadratic Ease In)
		# dist = 0.5 * accel * t^2.  accel = v_max / a
		return 0.5 * (v_max / a) * t * t
	elif t > (1.0 - a):
		# Deceleration phase (Quadratic Ease Out)
		# We process this as "1.0 minus the accel from the other side"
		var t_rem: float = 1.0 - t
		var dist_rem: float = 0.5 * (v_max / a) * t_rem * t_rem
		return 1.0 - dist_rem
	else:
		# Cruising phase (Linear)
		# Calculate position at end of accel phase
		var d_accel: float = 0.5 * v_max * a
		# Add linear distance
		return d_accel + v_max * (t - a)

func _on_sequence_complete() -> void:
	_is_active = false
	queue_redraw()
	sequence_finished.emit()
	if is_instance_valid(_target_player) and _target_player.has_method("set_physics_process"):
		_target_player.set_physics_process(true)

# Custom method to handle orbit updates every frame
func _process_orbit_step(current_angle_rad: float) -> void:
	if not is_instance_valid(_target_player): return

	# 1. Update Position (Polar to Cartesian)
	var offset: Vector2 = Vector2(cos(current_angle_rad), sin(current_angle_rad)) * orbit_radius
	_target_player.global_position = global_position + offset

	# 2. Update Rotation (Tangential)
	# This keeps the player facing the direction of travel during the orbit loop
	_target_player.rotation = current_angle_rad + (PI / 2.0)
