extends CharacterBody2D

signal exploded(pos, size, points)
signal player_collision(Area: Area2D)

const BIRD_OF_PREY_ENEMY = preload("res://resources/BirdOfPrey_enemy.tres")
const ENTERPRISE_TOS_ENEMY = preload("res://resources/enterpriseTOS_enemy.tres")

@export var enemy_data: Enemy  # Reference to the Enemy resource

@onready var sprite: Sprite2D = $Sprite2D  # Reference to the sprite node
@onready var collision_shape_node: CollisionShape2D = $Hitbox/CollisionShape2D  # Reference to the CollisionShape2D node
@onready var shield: Node = $enemyShield

# Variables for handling dynamic behavior
var move_speed: int
var rotation_rate: float
var shield_on: bool
var rate_of_fire: float
var bullet_speed: int
var bullet_life: float
var hp_max: int

var torpedo: PackedScene

#Enemy health variables
var hp_current: float = 100.0

var trans_length: float = 0.8

var playerAgro: bool = false
var endPoint: Vector2
var returnToStarbaseBool: bool = false
var moveTarget: String

#Shooting calculation variables
var angle_diff: float
var predicted_position
var randomized_position

var AI_enabled:bool = true
var player = null
var starbase  # Path to starbase, only set if AI_enabled is true

var shoot_cd: float = false

var RANDOMNESS_ANGLE_DEGREES

func _ready() -> void:
	SignalBus.enemy_type_changed.connect(change_enemy_resource)
	# Check if the resource is assigned
	if enemy_data:
		sync_to_resource()
			
	# Initialize AI-related data
	if AI_enabled:
		starbase = Utility.mainScene.starbase[0]
		Utility.mainScene.enemies.append(self)
	else:
		$AgroBox.queue_free()


	# Deferred call to set random target after initialization
	call_deferred("selectRandomPlanet")

	
func _process(delta):
	if hp_current <= 0:
		explode()

func _physics_process(delta):
	if not AI_enabled or not visible or not GameSettings.enemyMovement:
		return
	
	# Movement state setter
	setMovementState(delta)
	
	move_and_slide()

func sync_to_resource():
	# Assign values from the resource
	shield.sp_max = enemy_data.max_shield_health
	move_speed = enemy_data.default_speed
	rotation_rate = enemy_data.rotation_rate
	$AgroBox/CollisionShape2D.shape.radius = enemy_data.detection_radius  # Assign detection radius if it's related to hp
	hp_current = enemy_data.max_hp
	shield_on = enemy_data.shield_on
	rate_of_fire = enemy_data.rate_of_fire
	RANDOMNESS_ANGLE_DEGREES = enemy_data.RANDOMNESS_ANGLE_DEGREES

	# Set the sprite texture and scale if available
	if enemy_data.sprite_texture:
		sprite.texture = enemy_data.sprite_texture
		sprite.scale = Vector2(enemy_data.sprite_scale, enemy_data.sprite_scale)

	# Load the collision shape from the resource
	if enemy_data.collision_shape and collision_shape_node:
		$Hitbox/CollisionShape2D.shape = enemy_data.collision_shape
		$WorldCollisionShape.shape = enemy_data.collision_shape

	# Set bullet speed and lifetime from the torpedo resource
	if enemy_data.torpedo:
		torpedo = enemy_data.torpedo
	if torpedo:
		var torpedo_scene = torpedo.instantiate()
		bullet_speed = torpedo_scene.speed
		bullet_life = torpedo_scene.lifetime

		# Initialize shield settings
		shield.current_enemy_type = enemy_data.current_enemy_type
		shield.scale_shield()
		
		
func change_enemy_resource(ENEMY_TYPE):
	match ENEMY_TYPE:
		Utility.ENEMY_TYPE.BIRDOFPREY:
			enemy_data = BIRD_OF_PREY_ENEMY
			sync_to_resource()
		Utility.ENEMY_TYPE.ENTERPRISETOS:
			enemy_data = ENTERPRISE_TOS_ENEMY
			sync_to_resource()


func setMovementState(delta):
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
	
	
func selectRandomPlanet():
	endPoint = Utility.mainScene.planets.pick_random().global_position
	

	
func starbaseMovement(delta):
	if starbase:
		var starbaseLocation = starbase.global_position
		var direction = global_position.direction_to(starbase.position) # Sets movement direction to starbase
		moveToTarget("Starbase", starbaseLocation, delta)

func planetMovement(delta): 
	moveToTarget("Planet", endPoint, delta)
	
	
	if self.global_position.distance_to(endPoint) < 5:
		returnToStarbaseBool = true
	
func moveToTarget(targetName, targetPos, delta):
	var angle = (targetPos - self.global_position).angle() + deg_to_rad(90)
	var rotation_speed: float = rotation_rate * delta
	angle_diff = wrapf(angle - self.global_rotation, -PI, PI)
	
	rotation = lerp_angle(self.global_rotation, angle, min(rotation_speed / abs(angle_diff), 1))
	
	if targetName == "Player":
		velocity = (targetPos - self.global_position).normalized()*move_speed
	elif targetName == "Starbase":
		velocity = (targetPos - self.global_position).normalized()*move_speed
	elif targetName == "Planet":
		velocity = (targetPos - self.global_position).normalized()*move_speed
		
	move_and_slide()
	return angle_diff

func explode():
	Utility.mainScene.enemies.erase(self)
	self.queue_free()

func _on_hitbox_area_entered(area):
	if area.is_in_group("projectile") and area.shooter != "enemy":
		%TorpedoHit.play()
		area.queue_free()
		var damage_taken = area.damage
		hp_current -= damage_taken


func predict_player_position():
	var player_velocity = player.velocity
	var target_pos = player.position

	var a = bullet_speed*bullet_speed - player_velocity.dot(player_velocity)
	var b = -2*((target_pos-self.position).dot(player_velocity))
	var c= -(target_pos-self.position).dot(target_pos-self.position)
	
	var delta = (b*b)-(4*a*c)
	var solution
	
	if abs(a) < 0.0001:
		return -1  # Cannot solve the equation, invalid
		print("rounding error")
		
	if delta == 0:	
		solution = -b/(2*a)
	elif delta > 0:
		var solution1 = (-b + sqrt(delta)) / (2 * a)
		var solution2 = (-b - sqrt(delta)) / (2 * a)
		solution = max(solution1,solution2)
	else:
		return -1
		
	if solution > 0 and solution <= bullet_life:
		predicted_position = target_pos + player_velocity * solution
		randomized_position = randomize_position(predicted_position)
		return predicted_position
	else: #No firing solution possible
		predicted_position = player.global_position
		return player.global_position
	
func randomize_position(predicted_position) -> Vector2:
# Calculate the distance to the target
	var random_predicted_position
	var distance_to_target = self.global_position.distance_to(predicted_position)
	
	# Calculate the randomness radius (the size of the randomness circle)
	var randomness_radius = distance_to_target * tan(deg_to_rad(RANDOMNESS_ANGLE_DEGREES))
	
	# Generate a random point within the circle
	# Random angle between 0 and TAU (full circle)
	var random_angle = randf_range(0, TAU)
	
	# Random radius (scaled to fit inside the circle, not just at the edge)
	var random_radius = randomness_radius * sqrt(randf())  # sqrt ensures uniform distribution in circle
	
	# Convert polar coordinates (radius, angle) to Cartesian coordinates
	var random_offset_x = random_radius * cos(random_angle)
	var random_offset_y = random_radius * sin(random_angle)
	
	# Add the random offset to the predicted position
	random_predicted_position = predicted_position
	random_predicted_position.x += random_offset_x
	random_predicted_position.y += random_offset_y
	
	return random_predicted_position

func playerMovement(delta):
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
		var delta_x = randomized_position.x - self.global_position.x
		var delta_y = randomized_position.y - self.global_position.y

		# Calculate the angle using atan2
		var shooting_angle = atan2(delta_y, delta_x)

		return shooting_angle
	
	
func shoot_bullet():# Instantiate and configure bullet
	var angle = calculate_shooting_angle()
	if angle != -1.0:
		var bullet = torpedo.instantiate()
		bullet.global_position = self.global_position
		bullet.rotation = angle + deg_to_rad(90)  # Direction
		bullet.shooter = "enemy"
		# Velocity not needed as torpedo handles movement
		call_deferred("instantiate_bullet", bullet)


func instantiate_bullet(bullet):
	if !shoot_cd:
		shoot_cd = true
		get_parent().add_child(bullet)
		%LightTorpedo.play()
		await get_tree().create_timer(rate_of_fire).timeout
		shoot_cd = false
	
func _on_agro_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerAgro =  true
		player = body

func _on_agro_box_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerAgro =  false
		player = null
		angle_diff = TAU
