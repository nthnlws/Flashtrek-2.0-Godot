## NPC movement state machine. Owns the current State and steers the parent
## ship for it every physics frame. The owning character decides transitions
## on think_tick and feeds in destinations/targets.
class_name ShipMovementComponent
extends Node

signal state_changed(previous: State, current: State)
## Emitted every THINK_INTERVAL - owners make decisions here.
signal think_tick
signal waypoint_reached(index: int)
signal route_finished

enum State {
	PATROL,       ## Planet -> starbase loop
	FLEE,         ## Away from flee_point, returns to PATROL after FLEE_DURATION
	FORMATION,    ## Hold formation_offset behind formation_leader
	INVESTIGATE,  ## Move to investigate_position
	ENGAGE,       ## Manoeuvre around `target` per `profile`
	RETREAT,      ## Move to retreat_position and hold
	FOLLOW_ROUTE, ## Follow `route` while the player is within escort_leash
	DISABLED,     ## Drift
}

@export var ship: NeutralCharacter

const THINK_INTERVAL: float = 0.2
const FLEE_DURATION: float = 7.2
const FLEE_SPEED_MULT: float = 1.5
const PLANET_ARRIVAL_RADIUS: float = 150.0
const STARBASE_ARRIVAL_RADIUS: float = 1500.0
const RETREAT_ARRIVAL_RADIUS: float = 1200.0
const RETREAT_SPEED_MULT: float = 1.3
const FORMATION_CATCH_UP_DISTANCE: float = 600.0
const FORMATION_SPEED_MULT: float = 1.25
const ESCORT_SPEED_MULT: float = 0.6
const WAYPOINT_ARRIVAL_RADIUS: float = 300.0
const ATTACK_RUN_BREAK_DISTANCE: float = 1800.0
const ATTACK_RUN_BREAK_TIME: float = 4.0
const AVOID_MARGIN: float = 350.0
const AVOID_LOOKAHEAD: float = 3000.0
const PROJECTILE_SPEED: float = 1000.0
const PROJECTILE_LIFETIME: float = 7.5

var state: State = State.PATROL
## Seconds since the last state change.
var state_time: float = 0.0
var enabled: bool = true
var starbase: Node2D

var patrol_point: Vector2
var flee_point: Vector2
var investigate_position: Vector2
var retreat_position: Vector2

var target: Node2D
var profile: AIProfile = AIProfile.new()
## Lead-corrected aim at `target`, updated while ENGAGE.
var aim_point: Vector2
var is_facing_aim: bool = false

var formation_leader: CharacterBody2D
var formation_offset: Vector2 = Vector2.ZERO

var route: Array[Vector2] = []
var route_index: int = 0
var escort_leash: float = 3000.0

var _think_timer: float = 0.0
var _patrol_returning: bool = false
var _run_breaking_off: bool = false
var _break_off_point: Vector2
var _break_off_time: float = 0.0
var _orbit_direction: float = 1.0


func _ready() -> void:
	if ship == null:
		ship = get_parent() as NeutralCharacter
	if not LevelManager.starbases.is_empty():
		starbase = LevelManager.starbases.front()
	_think_timer = randf() * THINK_INTERVAL # Stagger ticks across ships
	_orbit_direction = [-1.0, 1.0].pick_random()

	pick_patrol_point.call_deferred()
	await get_tree().process_frame
	ship.rotation = ship.get_angle_to(patrol_point)


func _physics_process(delta: float) -> void:
	if not enabled or not ship.visible or not ship.health_component.alive:
		return

	state_time += delta
	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer += THINK_INTERVAL
		think_tick.emit()

	if state == State.FLEE and state_time >= FLEE_DURATION:
		pick_patrol_point()
		change_state(State.PATROL)

	_run_state(delta)
	ship.move_and_slide()


func change_state(new_state: State) -> void:
	if new_state == state:
		return
	var previous: State = state
	state = new_state
	state_time = 0.0
	is_facing_aim = false
	_run_breaking_off = false
	state_changed.emit(previous, new_state)


## Enters FLEE heading directly away from `from_position` (restarts the timer).
func flee_from(from_position: Vector2) -> void:
	var direction: Vector2 = (ship.global_position - from_position).normalized()
	flee_point = clamp_to_system(ship.global_position + direction * 10000.0)
	state_time = 0.0
	change_state(State.FLEE)


func pick_patrol_point() -> void:
	patrol_point = Vector2.ZERO if LevelManager.planets.is_empty() else LevelManager.planets.pick_random().global_position


func is_near(point: Vector2, radius: float) -> bool:
	return ship.global_position.distance_to(point) < radius


func has_reached_retreat() -> bool:
	return is_near(retreat_position, RETREAT_ARRIVAL_RADIUS)


# --- Per-state steering ---

func _run_state(delta: float) -> void:
	match state:
		State.PATROL:
			_run_patrol(delta)
		State.FLEE:
			move_to_target(flee_point, delta, FLEE_SPEED_MULT)
		State.INVESTIGATE:
			move_to_target(investigate_position, delta)
		State.FORMATION:
			_run_formation(delta)
		State.ENGAGE:
			if is_instance_valid(target):
				_run_combat(delta)
			else:
				apply_thrust(0.0, delta)
		State.RETREAT:
			if has_reached_retreat():
				apply_thrust(0.0, delta)
			else:
				move_to_target(retreat_position, delta, RETREAT_SPEED_MULT)
		State.FOLLOW_ROUTE:
			_run_route(delta)
		State.DISABLED:
			ship.velocity = ship.velocity.move_toward(Vector2.ZERO, ship.ship_stats.scaled_acceleration * delta)
			ship.rotation += 0.05 * delta


func _run_patrol(delta: float) -> void:
	var returning: bool = _patrol_returning and is_instance_valid(starbase)
	var destination: Vector2 = starbase.global_position if returning else patrol_point
	move_to_target(destination, delta)

	if is_near(destination, STARBASE_ARRIVAL_RADIUS if returning else PLANET_ARRIVAL_RADIUS):
		if returning:
			_patrol_returning = false
			pick_patrol_point()
		else:
			_patrol_returning = true


func _run_formation(delta: float) -> void:
	if not is_instance_valid(formation_leader):
		apply_thrust(0.0, delta)
		return

	var slot: Vector2 = formation_leader.global_position + formation_offset.rotated(formation_leader.global_rotation)
	var to_slot: Vector2 = slot - ship.global_position
	if to_slot.length() > FORMATION_CATCH_UP_DISTANCE:
		move_to_target(slot, delta, FORMATION_SPEED_MULT)
		return

	# In slot: match leader velocity/heading plus drift correction
	var stats: ShipState = ship.ship_stats
	var desired: Vector2 = (formation_leader.velocity + to_slot * 1.5).limit_length(stats.scaled_speed * FORMATION_SPEED_MULT)
	ship.velocity = ship.velocity.move_toward(desired, stats.scaled_acceleration * delta)
	turn_toward(wrapf(formation_leader.global_rotation - ship.global_rotation, -PI, PI), delta)


func _run_route(delta: float) -> void:
	if route_index >= route.size():
		apply_thrust(0.0, delta)
		return

	var player: Player = LevelManager.player
	if not is_instance_valid(player) or player.global_position.distance_to(ship.global_position) > escort_leash:
		ship.velocity = ship.velocity.move_toward(Vector2.ZERO, ship.ship_stats.scaled_acceleration * delta)
		return

	var waypoint: Vector2 = route[route_index]
	move_to_target(waypoint, delta, ESCORT_SPEED_MULT)
	if is_near(waypoint, WAYPOINT_ARRIVAL_RADIUS):
		route_index += 1
		waypoint_reached.emit(route_index)
		if route_index >= route.size():
			route_finished.emit()


## Moves according to profile.style and updates aim_point / is_facing_aim.
func _run_combat(delta: float) -> void:
	var origin: Vector2 = ship.global_position
	aim_point = predict_intercept(target)
	var to_target: Vector2 = target.global_position - origin
	var distance: float = to_target.length()
	var direction: Vector2 = to_target / maxf(distance, 1.0)
	var speed: float = ship.ship_stats.scaled_speed * profile.combat_speed_mult
	var preferred: float = profile.preferred_range
	var desired_velocity: Vector2 = Vector2.ZERO
	var face_point: Vector2 = aim_point
	var facing_error: float = absf(wrapf((aim_point - origin).angle() - ship.global_rotation, -PI, PI))
	var thrust_factor: float = clampf(1.0 - (facing_error / deg_to_rad(90.0)), 0.0, 1.0)

	match profile.style:
		AIProfile.Style.STANDOFF, AIProfile.Style.SIEGE:
			if distance > preferred:
				desired_velocity = direction * speed * thrust_factor
			elif distance < preferred * 0.6:
				desired_velocity = -direction * speed * 0.5
		AIProfile.Style.ORBIT:
			var tangent: Vector2 = direction.orthogonal() * _orbit_direction
			var radial: Vector2 = direction * clampf((distance - preferred) / preferred, -1.0, 1.0)
			desired_velocity = (tangent + radial * 1.5).normalized() * speed
		AIProfile.Style.KITE:
			if distance < preferred * 0.8:
				desired_velocity = -direction * speed
			elif distance > preferred * 1.2:
				desired_velocity = direction * speed * 0.8 * thrust_factor
			else:
				desired_velocity = direction.orthogonal() * _orbit_direction * speed * 0.4
		AIProfile.Style.ATTACK_RUN:
			if not _run_breaking_off:
				desired_velocity = direction * speed * maxf(thrust_factor, 0.3)
				if distance < preferred:
					_run_breaking_off = true
					_break_off_time = 0.0
					var overshoot: Vector2 = direction.rotated(randf_range(-0.6, 0.6)) * ATTACK_RUN_BREAK_DISTANCE
					_break_off_point = clamp_to_system(target.global_position + overshoot)
			else:
				_break_off_time += delta
				var to_break: Vector2 = _break_off_point - origin
				desired_velocity = to_break.normalized() * speed
				face_point = _break_off_point
				if to_break.length() < 250.0 or _break_off_time > ATTACK_RUN_BREAK_TIME:
					_run_breaking_off = false

	if desired_velocity.length_squared() > 1.0:
		var steer: Vector2 = apply_avoidance(origin + desired_velocity.normalized() * 1500.0) - origin
		desired_velocity = steer.normalized() * desired_velocity.length()

	ship.velocity = ship.velocity.move_toward(desired_velocity, ship.ship_stats.scaled_speed * delta * 2.0)
	turn_toward(wrapf((face_point - origin).angle() - ship.global_rotation, -PI, PI), delta)
	is_facing_aim = face_point == aim_point


## Lead-corrected position to fire at `body` with a PROJECTILE_SPEED shot.
func predict_intercept(body: Node2D) -> Vector2:
	var body_velocity: Vector2 = body.velocity if "velocity" in body else Vector2.ZERO
	var target_pos: Vector2 = body.global_position
	var to_target: Vector2 = target_pos - ship.global_position

	var a: float = PROJECTILE_SPEED * PROJECTILE_SPEED - body_velocity.dot(body_velocity)
	var b: float = -2.0 * to_target.dot(body_velocity)
	var c: float = -to_target.dot(to_target)
	var discriminant: float = b * b - 4.0 * a * c
	if absf(a) < 0.0001 or discriminant < 0.0:
		return target_pos

	var t1: float = (-b + sqrt(discriminant)) / (2.0 * a)
	var t2: float = (-b - sqrt(discriminant)) / (2.0 * a)
	var time: float = INF
	if t1 > 0.0: time = t1
	if t2 > 0.0: time = minf(time, t2)
	if time <= PROJECTILE_LIFETIME:
		return target_pos + body_velocity * time
	return target_pos


# --- Steering primitives ---

func move_to_target(target_pos: Vector2, delta: float, speed_mult: float = 1.0) -> void:
	var to_target: Vector2 = apply_avoidance(target_pos) - ship.global_position
	var angle_diff: float = wrapf(to_target.angle() - ship.global_rotation, -PI, PI)
	turn_toward(angle_diff, delta)
	# Thrust scales with how well the ship faces its heading
	apply_thrust(clampf(1.0 - absf(angle_diff) / deg_to_rad(90.0), 0.0, 1.0), delta, speed_mult)


func apply_thrust(thrust: float, delta: float, speed_mult: float = 1.0) -> void:
	var stats: ShipState = ship.ship_stats
	if thrust != 0.0:
		ship.velocity += ship.transform.x * thrust * stats.scaled_acceleration * delta
		ship.velocity = ship.velocity.limit_length(stats.scaled_speed * speed_mult)
	else:
		ship.velocity = ship.velocity.move_toward(Vector2.ZERO, stats.scaled_acceleration * delta * 0.25)


func turn_toward(angle_diff: float, delta: float) -> void:
	var max_turn: float = deg_to_rad(ship.ship_stats.scaled_agility * delta)
	# Ease off within 15 degrees
	var ease_factor: float = clampf(absf(angle_diff) / deg_to_rad(15.0), 0.0, 1.0)
	ship.rotation += clampf(angle_diff, -max_turn, max_turn) * ease_factor


## Returns a detour point around the nearest planet/sun blocking the path to
## `target_pos`. Obstacles containing `target_pos` are ignored.
func apply_avoidance(target_pos: Vector2) -> Vector2:
	var origin: Vector2 = ship.global_position
	var to_target: Vector2 = target_pos - origin
	var distance: float = to_target.length()
	if distance < 1.0:
		return target_pos

	var direction: Vector2 = to_target / distance
	var lookahead: float = minf(distance, AVOID_LOOKAHEAD)
	var nearest_along: float = INF
	var steer_pos: Vector2 = target_pos

	for obstacle in _get_obstacles():
		var center: Vector2 = obstacle.global_position
		var clearance: float = obstacle.get_obstacle_radius() + AVOID_MARGIN
		if center.distance_to(target_pos) < clearance:
			continue

		var to_obstacle: Vector2 = center - origin
		var along: float = to_obstacle.dot(direction)
		if along <= 0.0 or along > lookahead + clearance or along >= nearest_along:
			continue

		var lateral: Vector2 = to_obstacle - direction * along
		if lateral.length() >= clearance:
			continue

		nearest_along = along
		var side: Vector2 = -lateral.normalized() if lateral.length_squared() > 1.0 else direction.orthogonal()
		steer_pos = center + side * clearance * 1.3

	return steer_pos


## Nodes implementing get_obstacle_radius().
static func _get_obstacles() -> Array[Node2D]:
	var obstacles: Array[Node2D] = []
	for planet: Planet in LevelManager.planets:
		if is_instance_valid(planet):
			obstacles.append(planet)
	if is_instance_valid(LevelManager.sun):
		obstacles.append(LevelManager.sun)
	return obstacles


static func clamp_to_system(point: Vector2, margin: float = 2500.0) -> Vector2:
	var limit: float = 20000.0
	if LevelManager.current_system_data:
		limit = LevelManager.current_system_data.system_size
	limit -= margin
	return point.clamp(Vector2(-limit, -limit), Vector2(limit, limit))
