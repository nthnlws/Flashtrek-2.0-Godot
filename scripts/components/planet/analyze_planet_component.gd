extends Node2D
class_name AnalyzePlanetComponent

signal sequence_started
signal sequence_finished

const MISSION_INDICATOR = preload("uid://cj1a8ynj87xoc")
var indicator: MissionIndicator

# Configuration
@export var orbit_radius: float = 1500.0
@export var approach_duration: float = 1.5
@export var max_orbit_speed: float = 300.0
@export var orbit_color: Color = Color(0.2, 0.8, 1.0, 0.5)
var accel_fraction: float = 0.15 
# Internal State
var _target_player: Node2D = null
var _is_active: bool = false
var _orbit_start_angle: float = 0.0


func _ready() -> void:
	create_analyis_point()


func create_analyis_point() -> void:
	var new_indicator := MISSION_INDICATOR.instantiate()
	add_child(new_indicator)
	indicator = new_indicator
	indicator.scale = Vector2(4.0, 4.0)
	
	var mission_point:Vector2 = Utility.get_random_point_on_circle(1500.0)
	indicator.activate_indicator(mission_point)
	
	new_indicator.player_entered.connect(start_orbit_sequence)


func _handle_player_in_mission_area(player: Node2D) -> void:
	if !player.overdrive_active:
		indicator.deactivate_indicator()


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
	var previous_gamestate:Utility.GAMESTATE = Utility.current_gamestate
	Utility.current_gamestate = Utility.GAMESTATE.CUTSCENE
	indicator.queue_free() # Delete trigger indicator
	
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
	var duration: float = 4.0

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
	
	Utility.current_gamestate = previous_gamestate


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
