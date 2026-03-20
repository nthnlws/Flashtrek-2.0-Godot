extends NeutralCharacter
class_name FactionCharacter

@onready var muzzle: Node2D = $Muzzle
@onready var agro_area: CollisionShape2D = $AgroBox/CollisionShape2D
@onready var agro_box: Area2D = $AgroBox

# Variables for handling dynamic behavior
var fire_rate: float = 1.0
var shoot_randomness: float = 3.0
var difficulty_multiplier: float = 1.0

@export var torpedo: PackedScene

var enemyAgro: bool = false
var shoot_cd: bool = false

var enemy_target: Node = null


func _ready() -> void:
	super() # Runs NeutralCharacter _ready() function
	
	$hull_explosion.z_index = Utility.Z["Effects"]
	
	agro_box.body_entered.connect(_on_agro_box_body_entered)
	agro_box.body_exited.connect(_on_agro_box_body_exited)
	
	SignalBus.enemy_type_changed.connect(_sync_stats_to_resource)
	SignalBus.enemy_type_changed.connect(_sync_data_to_resource)
	SignalBus.playerDied.connect(_clear_agro)


func setMovementState(delta:float) -> void:
	if enemyAgro and enemy_target: # Movement toward target
		targetMovement(delta)
		moveTarget = MOVE_STATE.Enemy
	elif global_position.distance_to(starbase.global_position) < 1500 and moveTarget == MOVE_STATE.Starbase and moveTarget != MOVE_STATE.Planet:
		returnToStarbaseBool = false
		selectRandomPlanet()
		moveTarget = MOVE_STATE.Planet
	elif !enemyAgro and returnToStarbaseBool == false: # Movement toward picked planet
		planetMovement(delta)
		moveTarget = MOVE_STATE.Planet
	elif !enemyAgro and returnToStarbaseBool == true: # Move toward starbase
		starbaseMovement(delta)
		moveTarget = MOVE_STATE.Starbase
	else: print("No matching movement status")


func targetMovement(delta: float) -> void:
	var predicted_position: Vector2 = predict_ship_position()
	var randomized_position: Vector2 = randomize_position(predicted_position)
	var to_target: Vector2 = predicted_position - global_position
	var angle_diff: float = wrapf(to_target.angle() - global_rotation, -PI, PI)
	var distance_to_target: float = to_target.length()
	
	if absf(angle_diff) > PI / 6.0:
		# Angle diff > 30 degrees: rotate only, kill velocity immediately
		_rotate_toward_target(angle_diff, delta)
		velocity = Vector2.ZERO
	else:
		# Facing close enough to target: rotate and move
		_rotate_toward_target(angle_diff, delta)
		if distance_to_target > 1000:
			velocity = to_target.normalized() * move_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, 25.0 * delta)
	
	move_and_slide()
	if absf(angle_diff) < TAU / 12.0:
		shoot_bullet(predicted_position, randomized_position)


func predict_ship_position() -> Vector2:
	var enemy_velocity: Vector2 = enemy_target.velocity
	var target_pos: Vector2 = enemy_target.position
	var bullet_speed: float = 1000
	var bullet_life: float = 7.5

	var a: float = bullet_speed * bullet_speed - enemy_velocity.dot(enemy_velocity)
	var b: float = -2 * ((target_pos-self.position).dot(enemy_velocity))
	var c: float = -(target_pos-self.position).dot(target_pos-self.position)
	
	var delta: float = (b*b)-(4*a*c)
	var solution: float
	
	if abs(a) < 0.0001:
		return Vector2.ZERO  # Cannot solve the equation, invalid
		
	if delta == 0:
		solution = -b/(2*a)
	elif delta > 0:
		var solution1: float = (-b + sqrt(delta)) / (2 * a)
		var solution2: float = (-b - sqrt(delta)) / (2 * a)
		solution = max(solution1,solution2)
	else:
		return Vector2.ZERO
		
	if solution > 0 and solution <= bullet_life:
		var predicted_position: Vector2 = target_pos + enemy_velocity * solution
		return predicted_position
	else: #No firing solution possible
		var predicted_position: Vector2 = enemy_target.global_position
		return predicted_position


func randomize_position(predicted_position: Vector2) -> Vector2:
# Calculate the distance to the target
	var distance_to_target: float = self.global_position.distance_to(predicted_position)
	
	# Calculate the randomness radius (the size of the randomness circle)
	var randomness_radius: float = distance_to_target * tan(deg_to_rad(shoot_randomness))
	
	# Generate a random point within the circle
	# Random angle between 0 and TAU (full circle)
	var random_angle: float = randf_range(0, TAU)
	
	# Random radius (scaled to fit inside the circle, not just at the edge)
	var random_radius: float = randomness_radius * sqrt(randf())  # sqrt ensures uniform distribution in circle
	
	# Convert polar coordinates (radius, angle) to Cartesian coordinates
	var random_offset_x: float = random_radius * cos(random_angle)
	var random_offset_y: float = random_radius * sin(random_angle)
	
	# Add the random offset to the predicted position
	var random_predicted_position: Vector2 = predicted_position
	random_predicted_position.x += random_offset_x
	random_predicted_position.y += random_offset_y
	
	return random_predicted_position


func calculate_shooting_angle(predicted_position: Vector2, randomized_position: Vector2) -> float:
	if predicted_position == Vector2.ZERO or randomized_position == Vector2.ZERO:
		return -1.0
	var delta_x: float = randomized_position.x - global_position.x
	var delta_y: float = randomized_position.y - global_position.y
	return atan2(delta_y, delta_x)


func shoot_bullet(predicted_position:Vector2, randomized_position:Vector2) -> void:# Instantiate and configure bullet
	if shoot_cd: return
	
	var angle: float = calculate_shooting_angle(predicted_position, randomized_position)
	if angle != -1.0:
		shoot_cd = true
		
		# Prep torpedo to shoot
		var bullet: Torpedo = torpedo.instantiate()
		bullet.exceptions.append($hitbox_area)
		bullet.exceptions.append(shield.get_node("shield_area"))
		bullet.shooterObject = self
		bullet.damage = bullet.damage * difficulty_multiplier
		bullet.global_position = muzzle.global_position
		bullet.rotation = angle  # Direction
		bullet.faction = self.faction
		
		call_deferred("instantiate_bullet", bullet)


func instantiate_bullet(bullet: Area2D) -> void:
		get_parent().add_child(bullet)
		await get_tree().create_timer(fire_rate).timeout
		shoot_cd = false


var stored_enemies:Array = []
func _on_agro_box_body_entered(body) -> void:
	if stored_enemies.has(body):
		enemyAgro =  true
		enemy_target = body
	#print("self name: %s, target name: %s, Own faction: %s, target faction: %s, " % [self.name, body.name, self.faction, body.faction])
	if body.faction != self.faction and body.faction != Utility.FACTION.NEUTRAL:
		enemyAgro =  true
		enemy_target = body


func _on_agro_box_body_exited(body) -> void:
	if body == enemy_target:
		enemyAgro =  false
		enemy_target = null


func _set_aggression_to_shooter(shooter: Node) -> void:
	enemyAgro =  true
	enemy_target = shooter
	if !stored_enemies.has(shooter):
		stored_enemies.append(shooter)


func explode(hit_event:HitEvent = HitEvent.new()) -> void:
	shield.turnShieldOff()
	sprite.visible = false
	
	SignalBus.factionShipDied.emit(self)
	if hit_event.is_from_player: # Update reputation if died from player damage
		#print('killed by player')
		SignalBus.reputation_change_triggered.emit(self.faction, self.reputation_value)
	#else: print('not player kill')
	
	var random_pickup_type:int = randi_range(0, UpgradePickup.MODULE_TYPES.keys().size())
	SignalBus.spawnLoot.emit(random_pickup_type, self.global_position, 1)
	
	collision_shape.set_deferred("disabled", true)
	%ship_explosion.play()
	
	animation.visible = true
	animation.play("explode")
	await animation.animation_finished
	
	queue_free()


func _clear_agro() -> void:
	enemy_target = null
	enemyAgro = false
	stored_enemies.clear()
