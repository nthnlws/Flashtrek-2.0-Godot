extends PlanetComponent
class_name AnalyzePlanetComponent

signal sequence_started
signal sequence_finished

const MISSION_INDICATOR = preload("uid://cj1a8ynj87xoc")
var indicator: MissionIndicator

# Configuration
@export var orbit_radius: float = 1500.0
@export var approach_duration: float = 1.5
@export var orbit_duration: float = 7.0 # Seconds
@export var max_orbit_speed: float = 600.0
@export var orbit_color: Color = Color(0.2, 0.8, 1.0, 0.5)
@export var accel_fraction: float = 0.15 

@onready var tractor_beam: CinematicTractorBeam = $CinematicTractorBeam

# Internal State
var _target_player: Node2D = null
var _is_active: bool = false
var _orbit_start_angle: float = 0.0
var _total_arc_angle: float = 0.0 # How far we actually travel in radians


func _ready() -> void:
	create_analyis_point()


func create_analyis_point() -> void:
	var new_indicator: MissionIndicator = MISSION_INDICATOR.instantiate()
	add_child(new_indicator)
	indicator = new_indicator
	indicator.scale = Vector2(4.0, 4.0)
	
	var mission_point: Vector2 = Utility.get_random_point_on_circle(orbit_radius)
	indicator.activate_indicator(mission_point)
	
	new_indicator.player_entered.connect(start_orbit_sequence)


func start_orbit_sequence(player: Node2D) -> void:
	if _is_active: 
		return
		
	var previous_gamestate: Utility.GAMESTATE = Utility.current_gamestate
	Utility.current_gamestate = Utility.GAMESTATE.CUTSCENE
	
	if is_instance_valid(indicator):
		indicator.queue_free()
	
	_is_active = true
	_target_player = player
	sequence_started.emit()

	# 1. Disable Player
	_target_player.set_physics_process(false)
	if "velocity" in _target_player:
		_target_player.velocity = Vector2.ZERO

	# 2. Calculate Geometry
	var vector_to_player: Vector2 = _target_player.global_position - parent_planet.global_position
	_orbit_start_angle = vector_to_player.angle()
	
	var entry_pos: Vector2 = parent_planet.global_position + Vector2(cos(_orbit_start_angle), sin(_orbit_start_angle)) * orbit_radius
	var target_rot: float = _orbit_start_angle + (PI / 2.0)
	var final_rot_value: float = _target_player.rotation + angle_difference(_target_player.rotation, target_rot)

	# 3. Speed Math
	# To keep Duration fixed but use max_orbit_speed, we calculate the required Angle.
	# Because of the trapezoidal ease, the "Average Velocity" is Vmax * (1 - accel_fraction).
	var average_speed: float = max_orbit_speed * (1.0 - accel_fraction)
	var total_distance_pixels: float = average_speed * orbit_duration
	_total_arc_angle = total_distance_pixels / orbit_radius

	# 4. Tween Sequence
	var tween: Tween = create_tween()
	
	# PHASE A: Approach
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_target_player, "global_position", entry_pos, approach_duration)
	tween.tween_property(_target_player, "rotation", final_rot_value, approach_duration)
	
	# PHASE B: Orbit
	tween.chain().tween_method(_process_custom_orbit, 0.0, 1.0, orbit_duration)\
		.set_trans(Tween.TRANS_LINEAR)

	tween.finished.connect(_on_sequence_complete.bind(previous_gamestate))


func _process_custom_orbit(t: float) -> void:
	if not is_instance_valid(_target_player): 
		return

	# 1. Apply Trapezoidal Ease
	var curved_t: float = _get_trapezoidal_progress(t, accel_fraction)

	# 2. Calculate Angle based on calculated arc
	var current_angle: float = _orbit_start_angle + (curved_t * _total_arc_angle)

	# 3. Update Position & Rotation
	var offset: Vector2 = Vector2(cos(current_angle), sin(current_angle)) * orbit_radius
	_target_player.global_position = parent_planet.global_position + offset
	_target_player.rotation = current_angle + (PI / 2.0)
	
	# Tractor Beam updates
	var in_flat: bool = t >= accel_fraction and t <= (1.0 - accel_fraction)
	if in_flat:
		tractor_beam.global_position = _target_player.global_position
		tractor_beam.activate_toward(parent_planet)
	elif not in_flat and tractor_beam.beam_active:
		tractor_beam.deactivate()


func _get_trapezoidal_progress(t: float, a: float) -> float:
	if a <= 0.0: return t
	var v_max: float = 1.0 / (1.0 - a)
	
	if t < a:
		return 0.5 * (v_max / a) * t * t
	elif t > (1.0 - a):
		var t_rem: float = 1.0 - t
		return 1.0 - (0.5 * (v_max / a) * t_rem * t_rem)
	else:
		return (0.5 * v_max * a) + v_max * (t - a)


func _on_sequence_complete(old_state: Utility.GAMESTATE) -> void:
	_is_active = false
	Utility.current_gamestate = old_state
	sequence_finished.emit()
	
	if is_instance_valid(_target_player):
		_target_player.set_physics_process(true)
	
	MissionManager.complete_mission()
	
