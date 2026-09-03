extends NeutralCharacter
class_name FactionCharacter

@onready var firing_position: Marker2D = $FiringPosition
@onready var agro_area: CollisionShape2D = $AgroBox/CollisionShape2D
@onready var agro_box: Area2D = $AgroBox
@onready var weapons_component: WeaponsComponent = $WeaponsComponent

# Variables for handling dynamic behavior
var fire_rate: float = 1.0
var accuracy_cone_angle: float = 3.0 # Degrees
const VALID_FIRING_ANGLE: float = 30.0
var difficulty_multiplier: float = 1.0

var enemyAgro: bool = false
var shoot_cd: bool = false
var enemy_target: Node2D = null # Typed as Node2D for transform access
var stored_enemies: Array[Node2D] = []


func _ready() -> void:
	super() # Runs NeutralCharacter _ready() function
	
	$hull_explosion.z_index = Utility.Z["Effects"]
	
	SignalBus.enemy_type_changed.connect(sync_ship_to_resource)
	SignalBus.playerDied.connect(_clear_agro)
	
	await Engine.get_main_loop().process_frame
	
	agro_box.body_entered.connect(_on_agro_box_body_entered)
	agro_box.body_exited.connect(_on_agro_box_body_exited)
	
	if weapons_component:
		weapons_component.damage_multiplier = difficulty_multiplier


func setMovementState(delta: float) -> void:
	if enemyAgro and is_instance_valid(enemy_target): # Movement toward target
		targetMovement(delta)
		moveTarget = MOVE_STATE.Enemy
	elif global_position.distance_to(starbase.global_position) < 1500 and moveTarget == MOVE_STATE.Starbase and moveTarget != MOVE_STATE.Planet:
		returnToStarbaseBool = false
		selectRandomPlanet()
		moveTarget = MOVE_STATE.Planet
	elif not enemyAgro and returnToStarbaseBool == false: # Movement toward picked planet
		planetMovement(delta)
		moveTarget = MOVE_STATE.Planet
	elif not enemyAgro and returnToStarbaseBool == true: # Move toward starbase
		starbaseMovement(delta)
		moveTarget = MOVE_STATE.Starbase
	else: 
		print("No matching movement status")


func targetMovement(delta: float) -> void:
	var predicted_position: Vector2 = predict_ship_position()
	var to_target: Vector2 = predicted_position - global_position
	var angle_diff: float = wrapf(to_target.angle() - global_rotation, -PI, PI)
	var angle_abs: float = absf(angle_diff)
	var distance_to_target: float = to_target.length()
	
	_rotate_toward_target(angle_diff, delta)
	
	# Movement logic
	if distance_to_target > 1000.0:
		var thrust_factor: float = clampf(1.0 - (angle_abs / deg_to_rad(90.0)), 0.0, 1.0)
		var target_velocity: Vector2 = to_target.normalized() * ship_stats.scaled_speed * thrust_factor
		velocity = velocity.move_toward(target_velocity, ship_stats.scaled_speed * delta * 2.0)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ship_stats.scaled_speed * delta * 2.0)
	
	move_and_slide()
	
	# Shooting logic
	if is_instance_valid(weapons_component):
		weapons_component.attempt_primary_fire(predicted_position)


func predict_ship_position() -> Vector2:
	if not is_instance_valid(enemy_target):
		return global_position

	var enemy_velocity: Vector2 = enemy_target.velocity
	var target_pos: Vector2 = enemy_target.global_position
	var bullet_speed: float = 1000.0
	var bullet_life: float = 7.5

	var to_target: Vector2 = target_pos - global_position
	var a: float = (bullet_speed * bullet_speed) - enemy_velocity.dot(enemy_velocity)
	var b: float = -2.0 * to_target.dot(enemy_velocity)
	var c: float = -to_target.dot(to_target)
	
	var discriminant: float = (b * b) - (4.0 * a * c)
	
	if absf(a) < 0.0001 or discriminant < 0.0:
		return target_pos 

	var t1: float = (-b + sqrt(discriminant)) / (2.0 * a)
	var t2: float = (-b - sqrt(discriminant)) / (2.0 * a)
	
	var valid_times: Array[float] = []
	if t1 > 0: valid_times.append(t1)
	if t2 > 0: valid_times.append(t2)
	
	if valid_times.is_empty():
		return target_pos

	var solution: float = valid_times.min() # Get smallest positive time
	
	if solution <= bullet_life:
		return target_pos + (enemy_velocity * solution)
	
	return target_pos


func _on_agro_box_body_entered(body: Node2D) -> void:
	# Ignore if body is self or already the current target
	if body == self or body == enemy_target: return 
	
	# Check if known or hostile
	var is_hostile: bool = hostile_check(body)
	var is_known: bool = stored_enemies.has(body)
	
	# Trigger aggression if body was previosly hostile
	# or is part of an enemy faction
	if is_hostile or is_known:
		_set_target(body)


## Compare newly entered body faction to own faction to determine hostility status
func hostile_check(body: Node2D) -> bool:
	var check: bool = (body.ship_stats.current_faction != Utility.FACTION.NEUTRAL
	and self.ship_stats.current_faction != Utility.FACTION.NEUTRAL
	and body.ship_stats.current_faction != self.ship_stats.current_faction)
	
	return check


func _on_agro_box_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.combatantExited.emit(self)
		
	if body == enemy_target:
		# Instead of immediately losing agro, check if other valid enemies are still in the box
		_evaluate_remaining_targets()


func _set_aggression_to_shooter(shooter: Node2D) -> void:
	_set_target(shooter)


func _set_target(target: Node2D) -> void:
	if not enemyAgro:
		SignalBus.combatantEntered.emit(self)
		
	enemyAgro = true
	enemy_target = target
	
	if not stored_enemies.has(target):
		stored_enemies.append(target)


func _evaluate_remaining_targets() -> void:
	var overlapping = agro_box.get_overlapping_bodies()
	
	for body in overlapping:
		if stored_enemies.has(body) and is_instance_valid(body):
			enemy_target = body
			return # Found a new target, stay aggressive
			
	# No valid targets left in the area
	_clear_agro()


func _clear_agro() -> void:
	if enemyAgro:
		# Turns off player "in-combat" status if present
		SignalBus.combatantExited.emit(self)
	
	enemy_target = null
	enemyAgro = false
	stored_enemies.clear()


# Overwrites NeutralCharacter explode() function
func explode(hit_event: HitEvent = HitEvent.new()) -> void:
	shield.turnShieldOff()
	sprite.visible = false
	
	SignalBus.factionShipDied.emit(self)
	if hit_event.is_from_player: 
		SignalBus.reputation_change_triggered.emit(ship_stats.current_faction, ship_stats.reputation_value)
	
	var random_pickup_type: int = randi_range(0, UpgradePickup.MODULE_TYPES.keys().size())
	SignalBus.spawnLoot.emit(random_pickup_type, self.global_position, 1)
	
	collision_shape.set_deferred("disabled", true)
	%ship_explosion.play()
	
	animation.visible = true
	animation.play("explode")
	await animation.animation_finished
	
	queue_free()
