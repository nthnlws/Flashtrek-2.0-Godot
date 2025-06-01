extends CharacterBody2D

const FLEET_DATA := preload("res://assets/data/fleet_data.tres") as FleetData
var ship_name: String = str(Utility.SHIP_TYPES.Brel_Class)
var faction: String = str(Utility.FACTION.FEDERATION)

@onready var sprite: Sprite2D = $Sprite2D  # Reference to the sprite node
@onready var collision_shape: CollisionShape2D = $hitbox_area/CollisionShape2D  # Reference to the CollisionShape2D node
@onready var shield: Node = $enemyShield
@onready var muzzle: Node2D = $Muzzle
@onready var animation: AnimatedSprite2D = $hull_explosion
@onready var agro_area: CollisionShape2D = $AgroBox/CollisionShape2D
@onready var agro_box: Area2D = $AgroBox

# Variables for handling dynamic behavior
var move_speed: int = 60
var rotation_rate: float = 3.0
var shield_on: bool = true
var hp_max: int = 100
var fire_rate: float = 1.0
var shoot_randomness: float = 3.0

@export var torpedo: PackedScene

#Enemy health variables
var hp_current: float = 100.0

var alive: bool = true
var playerAgro: bool = false
var endPoint: Vector2
var returnToStarbaseBool: bool = false
var moveTarget: String

#Shooting calculation variables
var angle_diff: float
var predicted_position: Vector2
var randomized_position: Vector2

var AI_enabled:bool = true
var player: Player = null
var starbase: Node2D  # Path to starbase, only set if AI_enabled is true

var shoot_cd: float = false

func _init() -> void:
	if AI_enabled:
		Utility.mainScene.enemies.append(self)


func _ready() -> void:
	agro_box.body_entered.connect(_on_agro_box_body_entered)
	agro_box.body_exited.connect(_on_agro_box_body_exited)
	
	_sync_data_to_resource(Utility.SHIP_TYPES.Nebula_Class)
	_sync_stats_to_resource(Utility.SHIP_TYPES.Excelsior_Class)
	# Initialize AI-related data
	if AI_enabled:
		starbase = Utility.mainScene.starbase[0]
	else:
		agro_box.queue_free()

	# Set initial movement state target
	call_deferred("selectRandomPlanet")


func _sync_data_to_resource(ship:Utility.SHIP_TYPES):
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[ship]
	
	sprite.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
	faction = ship_data.FACTION
	shield.scale = Vector2(ship_data.SHIELD_SCALE_X, ship_data.SHIELD_SCALE_Y)


func _sync_stats_to_resource(ship:Utility.SHIP_TYPES):
	var ship_stats:Dictionary = Utility.SHIP_STATS.values()[ship]
	
	move_speed = ship_stats.SPEED
	shoot_randomness = ship_stats.SHOOT_RANDOM_DEGREES
	rotation_rate = ship_stats.ROTATION_SPEED
	hp_max = ship_stats.MAX_HP
	shield.sp_max = ship_stats.MAX_SHIELD
	agro_area.shape.radius = ship_stats.DETECTION_RADIUS
	fire_rate = ship_stats.SHOOT_SPEED


func _physics_process(delta: float) -> void:
	#TODO Sync Player and Enemy speed stats to be compatible
	if not AI_enabled or not visible or not GameSettings.enemyMovement or alive == false:
		return
	
	# Movement state setter
	setMovementState(delta)
	
	move_and_slide()


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


func selectRandomPlanet() -> void:
	endPoint = Utility.mainScene.planets.pick_random().global_position


func starbaseMovement(delta:float) -> void:
	if starbase:
		var starbaseLocation: Vector2 = starbase.global_position
		var direction = global_position.direction_to(starbase.position) # Sets movement direction to starbase
		moveToTarget("Starbase", starbaseLocation, delta)


func planetMovement(delta:float) -> void: 
	moveToTarget("Planet", endPoint, delta)
	
	
	if self.global_position.distance_to(endPoint) < 5:
		returnToStarbaseBool = true


func moveToTarget(targetName:String, targetPos:Vector2, delta: float) -> float:
	var angle: float = (targetPos - self.global_position).angle() + deg_to_rad(90)
	var rotation_speed: float = rotation_rate * delta
	angle_diff = wrapf(angle - self.global_rotation, -PI, PI)
	
	rotation = lerp_angle(self.global_rotation, angle, min(rotation_speed / abs(angle_diff), 1))
	
	velocity = (targetPos - self.global_position).normalized()*move_speed
		
	move_and_slide()
	return angle_diff


func explode() -> void:
	Utility.mainScene.enemies.erase(self)
	SignalBus.enemyDied.emit(self)
	shield.shieldDie()
	sprite.visible = false
	collision_shape.set_deferred("disabled", true)
	agro_area.set_deferred("disabled", true)
	%ship_explosion.play()
	alive = false
	animation.visible = true
	animation.play("explode")
	await animation.animation_finished
	queue_free()


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


func playerMovement(delta: float) -> void:
	predict_player_position()
	if typeof(predict_player_position()) == TYPE_INT:
		moveToTarget("Player", player.global_position, delta)
	else:
		moveToTarget("Player", predicted_position, delta)
	
	if abs(angle_diff) < TAU/12:
		shoot_bullet()


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
	if !shoot_cd:
		shoot_cd = true
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


func take_damage(damage:float, hit_pos: Vector2) -> void:
	hp_current -= damage
	
	Utility.createDamageIndicator(damage, Utility.damage_red, hit_pos)
	
	if hp_current <= 0 and alive:
		explode()
