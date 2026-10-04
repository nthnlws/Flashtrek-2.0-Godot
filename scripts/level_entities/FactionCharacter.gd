extends NeutralCharacter
class_name FactionCharacter

@onready var firing_position: Marker2D = $FiringPosition
@onready var agro_area: CollisionShape2D = $AgroBox/CollisionShape2D
@onready var agro_box: Area2D = $AgroBox
@onready var weapons_component: WeaponsComponent = $WeaponsComponent

## Defaults to AIProfile.for_archetype() of the hull.
@export var ai_profile_override: AIProfile

const HELP_RADIUS: float = 4000.0
const TARGET_SWITCH_MARGIN: float = 0.15
const INVESTIGATE_TIMEOUT: float = 12.0
const INVESTIGATE_ARRIVAL_RADIUS: float = 600.0
const PURSUIT_RANGE_MULT: float = 1.6
## Fraction of max hull per second.
const REPAIR_RATE: float = 0.05
const RETREAT_DISTANCE: float = 6000.0
const HOSTILE_REPUTATION: float = -2500.0
const ALLY_REPUTATION: float = PlayerReputation.NEUTRAL_THRESHOLD
const CONTRABAND_SCAN_TIME: float = 4.0
const FIRE_LANE_WIDTH: float = 90.0
const THREAT_DECAY_PER_THINK: float = 0.9

## Leader-local space, x = forward.
const FORMATION_OFFSETS: Array[Vector2] = [
	Vector2(-250, -220), Vector2(-250, 220), Vector2(-500, 0), Vector2(-500, -440), Vector2(-500, 440),
]

var ai_profile: AIProfile

## Mirrored to movement.target.
var enemy_target: Node2D = null:
	set(value):
		enemy_target = value
		if movement:
			movement.target = value
var stored_enemies: Array[Node2D] = []
## Attacker -> recent hit count, decays each think tick.
var _threat: Dictionary = {}
var _last_threat_position: Vector2
var _fire_lane_clear: bool = true
var _engaged_player: bool = false
var _contraband_scan_time: float = 0.0

## Null for leaders and solo ships. Mirrored to movement.formation_leader.
var squad_leader: FactionCharacter = null:
	set(value):
		squad_leader = value
		if movement:
			movement.formation_leader = value
var formation_offset: Vector2 = Vector2.ZERO:
	set(value):
		formation_offset = value
		if movement:
			movement.formation_offset = value


func _ready() -> void:
	super() # Runs NeutralCharacter _ready() function

	$hull_explosion.z_index = Utility.Z["Effects"]

	movement.state_changed.connect(_on_movement_state_changed)
	SignalBus.enemy_type_changed.connect(sync_ship_to_resource.unbind(1))
	SignalBus.playerDied.connect(_forget_player)
	SignalBus.ship_distress.connect(_on_ship_distress)


func sync_ship_to_resource() -> void:
	super() # Runs NeutralCharacters sync function
	weapons_component.ship_damage_multiplier = ship_stats.scaled_damage_mult
	if ai_profile_override:
		ai_profile = ai_profile_override
	else:
		ai_profile = AIProfile.for_archetype(Utility.get_ship_stats(ship_stats.ship_type).archetype)
	movement.profile = ai_profile


func _physics_process(_delta: float) -> void:
	if movement.state == AIState.ENGAGE and movement.is_facing_aim and _fire_lane_clear and is_instance_valid(weapons_component):
		weapons_component.attempt_primary_fire(movement.aim_point)


# --- Decisions ---

func _on_movement_state_changed(previous: ShipMovementComponent.State, current: ShipMovementComponent.State) -> void:
	if previous == AIState.ENGAGE:
		_set_engaged_player(false)
	if current == AIState.RETREAT:
		enemy_target = null
		movement.retreat_position = _pick_retreat_position()


func _think() -> void:
	_prune_references()

	match movement.state:
		AIState.PATROL, AIState.FORMATION, AIState.INVESTIGATE:
			_think_idle()
		AIState.ENGAGE:
			_think_engage()
		AIState.RETREAT:
			_think_retreat()


func _think_idle() -> void:
	if _should_retreat():
		movement.change_state(AIState.RETREAT)
		return

	_check_contraband_scan()

	var target: Node2D = _select_target()
	if target:
		_set_target(target)
		return

	match movement.state:
		AIState.INVESTIGATE:
			var arrived: bool = movement.is_near(movement.investigate_position, INVESTIGATE_ARRIVAL_RADIUS)
			if arrived or movement.state_time > INVESTIGATE_TIMEOUT:
				_go_idle()
		AIState.PATROL:
			if _has_live_leader():
				movement.change_state(AIState.FORMATION)
		AIState.FORMATION:
			if not _has_live_leader():
				_reform_squad()
				_go_idle()


func _think_engage() -> void:
	if _should_retreat():
		movement.change_state(AIState.RETREAT)
		return

	var target: Node2D = _select_target()
	if target == null:
		if is_instance_valid(enemy_target):
			_investigate(enemy_target.global_position)
		else:
			_go_idle()
		return

	if target != enemy_target:
		_set_target(target)
	if is_instance_valid(enemy_target):
		_last_threat_position = enemy_target.global_position
	_fire_lane_clear = _is_fire_lane_clear()


func _idle_state() -> ShipMovementComponent.State:
	return AIState.FORMATION if _has_live_leader() else AIState.PATROL


func _go_idle() -> void:
	stored_enemies.clear()
	_threat.clear()
	enemy_target = null
	movement.change_state(_idle_state())


func _investigate(point: Vector2) -> void:
	movement.investigate_position = point
	movement.change_state(AIState.INVESTIGATE)


# --- Targeting ---

func _set_target(target: Node2D) -> void:
	_remember_enemy(target)
	enemy_target = target
	_last_threat_position = target.global_position
	_set_engaged_player(target.is_in_group("player"))
	if movement.state != AIState.ENGAGE:
		movement.change_state(AIState.ENGAGE)
		_alert_squad(target)


func _remember_enemy(body: Node2D) -> void:
	if is_instance_valid(body) and not stored_enemies.has(body):
		stored_enemies.append(body)


func _agro_radius() -> float:
	var circle: CircleShape2D = agro_area.shape as CircleShape2D
	return circle.radius if circle else 1250.0


## Scores by distance, threat and target damage. Keeps the current target
## unless another beats it by TARGET_SWITCH_MARGIN.
func _select_target() -> Node2D:
	var best: Node2D = null
	var best_score: float = -INF
	var current_score: float = -INF

	for candidate: Node2D in _gather_candidates():
		var score: float = _score_target(candidate)
		if candidate == enemy_target:
			current_score = score
		if score > best_score:
			best_score = score
			best = candidate

	if is_instance_valid(enemy_target) and current_score > -INF and best_score < current_score + TARGET_SWITCH_MARGIN:
		return enemy_target
	return best


func _gather_candidates() -> Array[Node2D]:
	var candidates: Array[Node2D] = []
	for body: Node2D in agro_box.get_overlapping_bodies():
		if _is_targetable(body) and is_hostile_to(body):
			candidates.append(body)

	var pursuit_range: float = _agro_radius() * PURSUIT_RANGE_MULT
	for enemy: Node2D in stored_enemies:
		if candidates.has(enemy) or not _is_targetable(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= pursuit_range:
			candidates.append(enemy)
	return candidates


func _score_target(target: Node2D) -> float:
	var pursuit_range: float = _agro_radius() * PURSUIT_RANGE_MULT
	var distance_score: float = 1.0 - clampf(global_position.distance_to(target.global_position) / pursuit_range, 0.0, 1.0)
	var threat_score: float = clampf(float(_threat.get(target, 0.0)) / 3.0, 0.0, 1.0)
	var weakness_score: float = 0.0
	if "health_component" in target and target.health_component:
		var target_health: HealthComponent = target.health_component
		weakness_score = 1.0 - clampf(target_health.getCurrentHP() / maxf(target_health.getMaxHealth(), 1.0), 0.0, 1.0)
	return distance_score * 0.45 + threat_score * 0.35 + weakness_score * 0.2 + _target_bonus(target)


func _target_bonus(_target: Node2D) -> float:
	return 0.0


func _is_targetable(body: Node2D) -> bool:
	if not is_instance_valid(body) or body == self:
		return false
	if "cloaked" in body and body.cloaked:
		return false
	if "health_component" in body and body.health_component and not body.health_component.alive:
		return false
	return true


func is_hostile_to(body: Node2D) -> bool:
	if not is_instance_valid(body) or body == self or not ("ship_stats" in body) or body.ship_stats == null:
		return false
	if stored_enemies.has(body):
		return true
	if body.is_in_group("player"):
		return _is_hostile_to_player()
	var mine: Utility.FACTION = ship_stats.current_faction
	var theirs: Utility.FACTION = body.ship_stats.current_faction
	return mine != Utility.FACTION.NEUTRAL and theirs != Utility.FACTION.NEUTRAL and mine != theirs


func _is_hostile_to_player() -> bool:
	var faction: Utility.FACTION = ship_stats.current_faction
	if faction == Utility.FACTION.NEUTRAL:
		return false
	if MissionManager.is_player_wanted_by(faction):
		return true
	return MissionManager.Reputation.get_reputation(faction) <= HOSTILE_REPUTATION


func is_allied_to_player() -> bool:
	var faction: Utility.FACTION = ship_stats.current_faction
	if faction == Utility.FACTION.NEUTRAL or _is_hostile_to_player():
		return false
	return MissionManager.Reputation.get_reputation(faction) >= ALLY_REPUTATION


## Passive ships never fight or answer distress calls.
func _is_passive() -> bool:
	return false


func _prune_references() -> void:
	stored_enemies.assign(stored_enemies.filter(func(enemy: Variant) -> bool: return is_instance_valid(enemy) and _is_targetable(enemy)))
	for attacker: Variant in _threat.keys():
		if not is_instance_valid(attacker):
			_threat.erase(attacker)
			continue
		_threat[attacker] *= THREAT_DECAY_PER_THINK
	if enemy_target and not _is_targetable(enemy_target):
		enemy_target = null


func _set_engaged_player(engaged: bool) -> void:
	if engaged == _engaged_player:
		return
	_engaged_player = engaged
	if engaged:
		SignalBus.combatantEntered.emit(self)
	else:
		SignalBus.combatantExited.emit(self)


func _forget_player() -> void:
	var player: Player = LevelManager.player
	stored_enemies.erase(player)
	_threat.erase(player)
	if enemy_target == player:
		enemy_target = null
		_set_engaged_player(false)
		if movement.state == AIState.ENGAGE:
			_go_idle()


# --- Firing ---

func _is_fire_lane_clear() -> bool:
	if not is_instance_valid(enemy_target):
		return false
	var lane: Vector2 = enemy_target.global_position - global_position
	var lane_length: float = lane.length()
	if lane_length < 1.0:
		return true
	var direction: Vector2 = lane / lane_length

	for ally: Node2D in _get_allies():
		var offset: Vector2 = ally.global_position - global_position
		var along: float = offset.dot(direction)
		if along <= 0.0 or along >= lane_length:
			continue
		if (offset - direction * along).length() < FIRE_LANE_WIDTH:
			return false
	return true


func _get_allies() -> Array[Node2D]:
	var allies: Array[Node2D] = []
	var faction: Utility.FACTION = ship_stats.current_faction
	var ships: Array[Node2D] = []
	ships.append_array(LevelManager.factionShips)
	ships.append_array(LevelManager.missionShips)
	for ship: Node2D in ships:
		if ship != self and is_instance_valid(ship) and faction_of(ship) == faction and ship != enemy_target:
			allies.append(ship)
	if is_instance_valid(LevelManager.player) and is_allied_to_player():
		allies.append(LevelManager.player)
	return allies


# --- Retreat ---

func _can_retreat() -> bool:
	return true


func _should_retreat() -> bool:
	return _can_retreat() and get_hull_fraction() < ai_profile.retreat_hull_fraction


func _pick_retreat_position() -> Vector2:
	# Own-faction starbase, otherwise away from the last threat
	var system: SystemData = LevelManager.current_system_data
	if is_instance_valid(movement.starbase) and system and system.faction == ship_stats.current_faction:
		return movement.starbase.global_position
	var away: Vector2 = (global_position - _last_threat_position).normalized()
	if away == Vector2.ZERO:
		away = Vector2.from_angle(randf() * TAU)
	return ShipMovementComponent.clamp_to_system(global_position + away * RETREAT_DISTANCE)


func _think_retreat() -> void:
	if get_hull_fraction() >= ai_profile.rejoin_hull_fraction:
		_return_from_retreat()
		return
	if not movement.has_reached_retreat():
		return

	# No repairs with a hostile in range
	for body: Node2D in agro_box.get_overlapping_bodies():
		if _is_targetable(body) and is_hostile_to(body):
			return
	var max_hp: float = health_component.getMaxHealth()
	var repair: float = max_hp * REPAIR_RATE * ShipMovementComponent.THINK_INTERVAL
	health_component.setCurrentHealth(minf(health_component.getCurrentHP() + repair, max_hp))


func _return_from_retreat() -> void:
	var enemies_left: bool = stored_enemies.any(func(enemy: Variant) -> bool: return is_instance_valid(enemy) and _is_targetable(enemy))
	if enemies_left:
		_investigate(_last_threat_position)
	else:
		_go_idle()


# --- Calls for help ---

func _on_hit_received(shooter: Node) -> void:
	var attacker: Node2D = shooter as Node2D
	if not is_instance_valid(attacker) or attacker == self or _is_friendly_fire(attacker):
		return

	_threat[attacker] = float(_threat.get(attacker, 0.0)) + 1.0
	_remember_enemy(attacker)
	_last_threat_position = attacker.global_position
	_emit_distress(attacker)

	if movement.state != AIState.ENGAGE and movement.state != AIState.RETREAT and not _is_passive():
		_set_target(attacker)


func _is_friendly_fire(attacker: Node2D) -> bool:
	if attacker.is_in_group("player"):
		return false
	var faction: Utility.FACTION = ship_stats.current_faction
	return faction != Utility.FACTION.NEUTRAL and faction_of(attacker) == faction


func _on_ship_distress(victim: Node2D, attacker: Node2D) -> void:
	if victim == self or attacker == self or not is_instance_valid(victim) or not is_instance_valid(attacker):
		return
	if _is_passive() or not health_component.alive:
		return
	if movement.state == AIState.ENGAGE or movement.state == AIState.RETREAT:
		return
	if global_position.distance_to(victim.global_position) > HELP_RADIUS:
		return
	if not _should_answer_distress(victim, attacker):
		return

	_remember_enemy(attacker)
	if global_position.distance_to(attacker.global_position) <= _agro_radius():
		_set_target(attacker)
	else:
		_last_threat_position = attacker.global_position
		_investigate(victim.global_position)


func _should_answer_distress(victim: Node2D, attacker: Node2D) -> bool:
	var faction: Utility.FACTION = ship_stats.current_faction
	if faction == Utility.FACTION.NEUTRAL:
		return false
	if not attacker.is_in_group("player") and faction_of(attacker) == faction:
		return false

	if victim.is_in_group("player"):
		return is_allied_to_player()

	var victim_faction: Utility.FACTION = faction_of(victim)
	if victim_faction == faction:
		return true
	# Local police protect neutral traffic
	if victim_faction == Utility.FACTION.NEUTRAL and LevelManager.current_system_data:
		return LevelManager.current_system_data.faction == faction
	return false


# --- Squads ---

func _has_live_leader() -> bool:
	return is_instance_valid(squad_leader) and squad_leader.health_component.alive


func _alert_squad(target: Node2D) -> void:
	if ship_stats.squad_id.is_empty():
		return
	for mate: FactionCharacter in _get_squad_members():
		if mate != self and (mate.movement.state == AIState.PATROL or mate.movement.state == AIState.FORMATION):
			mate._set_target(target)


func _get_squad_members() -> Array[FactionCharacter]:
	var members: Array[FactionCharacter] = []
	for ship: FactionCharacter in LevelManager.factionShips:
		if is_instance_valid(ship) and ship.health_component.alive and ship.ship_stats.squad_id == ship_stats.squad_id:
			members.append(ship)
	return members


## Promotes the lowest surviving formation_slot and reassigns slots.
func _reform_squad() -> void:
	if ship_stats.squad_id.is_empty():
		squad_leader = null
		return
	link_squad(_get_squad_members())


## Lowest formation_slot leads; the rest get FORMATION_OFFSETS slots.
static func link_squad(members: Array[FactionCharacter]) -> void:
	if members.is_empty():
		return
	members.sort_custom(func(a: FactionCharacter, b: FactionCharacter) -> bool: return a.ship_stats.formation_slot < b.ship_stats.formation_slot)
	var leader: FactionCharacter = members[0]
	leader.squad_leader = null
	for i: int in range(1, members.size()):
		members[i].squad_leader = leader
		members[i].formation_offset = FORMATION_OFFSETS[(i - 1) % FORMATION_OFFSETS.size()]


static func link_all_squads(ships: Array[FactionCharacter]) -> void:
	var squads: Dictionary = {}
	for ship: FactionCharacter in ships:
		if ship.ship_stats.squad_id.is_empty():
			continue
		if not squads.has(ship.ship_stats.squad_id):
			var new_squad: Array[FactionCharacter] = []
			squads[ship.ship_stats.squad_id] = new_squad
		squads[ship.ship_stats.squad_id].append(ship)
	for members: Array[FactionCharacter] in squads.values():
		link_squad(members)


# --- Contraband ---

## Detects the player after CONTRABAND_SCAN_TIME inside the agro box.
func _check_contraband_scan() -> void:
	var faction: Utility.FACTION = ship_stats.current_faction
	var player: Player = LevelManager.player
	if not MissionManager.is_contraband_scanner(faction) or not is_instance_valid(player) or player.cloaked:
		_contraband_scan_time = 0.0
		return

	if not agro_box.overlaps_body(player):
		_contraband_scan_time = 0.0
		return

	if is_zero_approx(_contraband_scan_time):
		SignalBus.changePopMessage.emit("A %s patrol is scanning your cargo hold..." % Utility.FACTION.keys()[faction].capitalize())
	_contraband_scan_time += ShipMovementComponent.THINK_INTERVAL
	if _contraband_scan_time >= CONTRABAND_SCAN_TIME:
		MissionManager.report_contraband_detected()
		_set_target(player)


# Overwrites NeutralCharacter explode() function
func explode(hit_event: HitEvent = HitEvent.new()) -> void:
	shield.turnShieldOff()
	sprite.visible = false
	_set_engaged_player(false)

	SignalBus.factionShipDied.emit(self)
	if hit_event.is_from_player:
		SignalBus.reputation_change_triggered.emit(ship_stats.current_faction, ship_stats.reputation_value)

	var random_pickup_type: int = randi_range(0, UpgradePickup.MODULE_TYPES.size() - 1)
	SignalBus.spawnLoot.emit(random_pickup_type, self.global_position, 1)

	collision_shape.set_deferred("disabled", true)
	%ship_explosion.play()

	animation.visible = true
	animation.play("explode")
	await animation.animation_finished

	queue_free()
