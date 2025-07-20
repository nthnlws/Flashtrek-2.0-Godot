extends NeutralCharacter
class_name EnemyCharacter


@onready var muzzle: Node2D = $Muzzle
@onready var agro_area: CollisionShape2D = $AgroBox/CollisionShape2D
@onready var agro_box: Area2D = $AgroBox

# Variables for handling dynamic behavior
var fire_rate: float = 1.0
var shoot_randomness: float = 3.0

@export var torpedo: PackedScene

#Enemy health variables
var playerAgro: bool = false

#Shooting calculation variables
var predicted_position: Vector2
var randomized_position: Vector2
var shoot_cd: float = false

var player: Player = null


func _ready() -> void:
	ship_type = "EnemyShip"
	super() # Runs NeutralCharacter _ready() function
	
	SignalBus.enemy_type_changed.connect(_sync_data_to_resource)
	SignalBus.enemy_type_changed.connect(_sync_stats_to_resource)
	agro_box.body_entered.connect(_on_agro_box_body_entered)
	agro_box.body_exited.connect(_on_agro_box_body_exited)
	
	_sync_data_to_resource(Utility.SHIP_TYPES.D5_Class)
	_sync_stats_to_resource(Utility.SHIP_TYPES.D5_Class)
	
	# Initialize AI-related data
	if not AI_enabled:
		agro_box.queue_free()


func setMovementState(delta:float) -> void:
	if player: # Movement toward player
		playerMovement(delta)
		moveTarget = "Player"
	elif global_position.distance_to(starbase.global_position) < 1500 and moveTarget == "Starbase":
		returnToStarbaseBool = false
		selectRandomPlanet()
		moveTarget = "Planet"
	elif !player and returnToStarbaseBool == false: # Movement toward picked planet
		planetMovement(delta)
		moveTarget = "Planet"
	elif !player and returnToStarbaseBool == true: # Move toward starbase
		starbaseMovement(delta)
		moveTarget = "Starbase"
	else: print("No matching movement status")


func playerMovement(delta: float) -> void:
	predict_player_position()
	if typeof(predict_player_position()) == TYPE_INT:
		moveToTarget("Player", player.global_position, delta)
	else:
		moveToTarget("Player", predicted_position, delta)
	
	if abs(angle_diff) < TAU/12:
		shoot_bullet()


func predict_player_position() -> Vector2:
	var player_velocity: Vector2 = player.velocity
	var target_pos: Vector2 = player.position
	var bullet_speed: float = 1000
	var bullet_life: float = 7.5

	var a: float = bullet_speed * bullet_speed - player_velocity.dot(player_velocity)
	var b: float = -2 * ((target_pos-self.position).dot(player_velocity))
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
		predicted_position = target_pos + player_velocity * solution
		randomized_position = randomize_position(predicted_position)
		return predicted_position
	else: #No firing solution possible
		predicted_position = player.global_position
		return player.global_position


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


func calculate_shooting_angle() -> float:
	if typeof(predicted_position) == TYPE_INT or typeof(predicted_position) == TYPE_NIL:
		return -1.0 # No valid firing solution
	if typeof(randomized_position) == TYPE_NIL:
		return -1.0 # No valid firing solution
	else:
		var delta_x: float = randomized_position.x - self.global_position.x
		var delta_y: float = randomized_position.y - self.global_position.y

		# Calculate the angle using atan2
		var shooting_angle: float = atan2(delta_y, delta_x)

		return shooting_angle


func shoot_bullet() -> void:# Instantiate and configure bullet
	if shoot_cd: return
	shoot_cd = true
	
	var angle: float = calculate_shooting_angle()
	if angle != -1.0:
		# Prep torpedo to shoot
		var bullet: Area2D = torpedo.instantiate()
		bullet.global_position = muzzle.global_position
		bullet.rotation = angle + deg_to_rad(90)  # Direction
		
		bullet.set_collision_layer_value(10, true) # Sets layer to enemy projectile
		bullet.set_collision_mask_value(2, true) # Turns on player hitbox
		bullet.set_collision_mask_value(7, true) # Turns on player shield
		
		call_deferred("instantiate_bullet", bullet)


func instantiate_bullet(bullet: Area2D) -> void:
		get_parent().add_child(bullet)
		%LightTorpedo.play()
		await get_tree().create_timer(fire_rate).timeout
		shoot_cd = false


func _on_agro_box_body_entered(body) -> void:
	if body.is_in_group("player"):
		playerAgro =  true
		player = body


func _on_agro_box_body_exited(body) -> void:
	if body.is_in_group("player"):
		playerAgro =  false
		player = null
		angle_diff = TAU

func explode() -> void:
	alive = false
	shield.shieldDie()
	sprite.visible = false
	
	Utility.mainScene.enemyShips.erase(self)
	SignalBus.spawnLoot.emit(UpgradePickup.MODULE_TYPES.DAMAGE, self.global_position)
	SignalBus.enemyShipDied.emit(self)
	
	collision_shape.set_deferred("disabled", true)
	%ship_explosion.play()
	
	animation.visible = true
	animation.play("explode")
	await animation.animation_finished
	
	queue_free()
