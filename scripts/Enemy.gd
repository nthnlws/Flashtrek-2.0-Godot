extends CharacterBody2D

signal exploded(pos, size, points)
signal player_collision(Area: Area2D)

@export var AI_enabled:bool = true
@export var default_speed:int = 50
@export var torpedo: PackedScene

var speed:int = default_speed
var shield_on:bool


#Enemy health variables
@export var hp_max:int = 50
var hp_current:float = hp_max

var trans_length:float= 0.8

var playerAgro:bool = false
var endPoint:Vector2
var returnToStarbaseBool:bool = false
var moveTarget:String

var player = null
var starbase #Path to starbase, only set if AI_enabled is true

var shoot_cd:float = false
var rate_of_fire:float = 1.0
var bullet_speed:int

	
func _ready() -> void:
	#Sets bullet speed for use in targeting calculation
	var torpedo_scene = torpedo.instantiate()
	bullet_speed = torpedo_scene.speed
	
	#Sets targets for movement if AI is enabled
	if AI_enabled:
		starbase = get_node("/root/Game/Level/Starbase")
		LevelData.enemies.append(self)
	elif AI_enabled == false:
		$AgroBox.queue_free()
		
	if GameSettings.enemyShield == true:
		var shieldScene = preload("res://scenes/enemyShield.tscn")
		var newShield = shieldScene.instantiate()
		add_child(newShield)
		
	call_deferred("selectRandomPlanet")
	
func _process(delta):
	if hp_current <= 0:
		explode()

func _physics_process(delta):
	if not AI_enabled or not visible or not GameSettings.enemyMovement:
		return
	
	# Movement state setter
	if player: # Movement toward player
		fire_at_predicted_position()
		moveTarget = "Player"
	elif !player and returnToStarbaseBool == false: # Movement toward picked planet
		planetMovement()
		moveTarget = "Planet"
	elif !player and returnToStarbaseBool == true:
		starbaseMovement()
		moveTarget = "Starbase"
	elif global_position - starbase.global_position < 1500:
		returnToStarbaseBool = false
		selectRandomPlanet()

	else: print("No matching movement status")
	move_and_slide()


func selectRandomPlanet():
	endPoint = LevelData.planets.pick_random().global_position

	
func starbaseMovement():
	if starbase:
		var starbaseLocation = starbase.global_position
		var direction = global_position.direction_to(starbase.position) # Sets movement direction to starbase
		moveToTarget(direction, "Starbase", starbaseLocation)

func planetMovement(): 
	var direction = global_position.angle_to_point(endPoint) + deg_to_rad(90)
	moveToTarget(direction, "Planet", endPoint)
	
	
	if self.global_position.distance_to(endPoint) < 5:
		returnToStarbaseBool = true
	
func moveToTarget(direction, targetName, targetPosition):
	rotation = lerp_angle(rotation, direction, 0.1)
	
	if targetName == "Player":
		velocity = (targetPosition - self.global_position).normalized()*speed
	elif targetName == "Starbase":
		velocity = (targetPosition - self.global_position).normalized()*speed
	elif targetName == "Planet":
		velocity = (targetPosition - self.global_position).normalized()*speed
		
	move_and_slide()

func explode():
	LevelData.enemies.erase(self)
	self.queue_free()

func _on_hitbox_area_entered(area):
	if area.is_in_group("projectile") and area.shooter != "enemy":
		$TorpedoHit.play()
		area.queue_free()
		var damage_taken = area.damage
		hp_current -= damage_taken


func predict_player_position(player_pos: Vector2, player_velocity: Vector2, enemy_pos: Vector2) -> Vector2:
	# Calculate the vector from the enemy to the player
	var to_player = player_pos - enemy_pos

	# Calculate the time it will take for the bullet to reach the player
	var time_to_impact = to_player.length() / bullet_speed

	# Predict the future position of the player
	var predicted_player_pos = player_pos + player_velocity * time_to_impact
	
	return predicted_player_pos

func fire_at_predicted_position():
	
	# Assume these values are provided or calculated elsewhere in your script
	var player_pos = player.global_position

	var player_velocity = player.velocity  # This should be the player's velocity vector
	var enemy_pos = global_position

	# Predict where the player will be
	var target_position = predict_player_position(player_pos, player_velocity, enemy_pos)

	# Calculate the direction to shoot at
	var direction = enemy_pos.angle_to_point(target_position) + deg_to_rad(90)

	# Shoot the bullet in that direction
	shoot_bullet(direction)
	moveToTarget(direction, "Player", target_position)

func shoot_bullet(direction: float):
	# Instantiate and configure your bullet here
	var bullet = torpedo.instantiate()
	bullet.global_position = self.global_position
	bullet.rotation = direction #direction
	bullet.shooter = "enemy"
	# Velocity not needed as torpedo handles movement
	call_deferred("instantiate_bullet", bullet)


func instantiate_bullet(bullet):
	if !shoot_cd:
		shoot_cd = true
		get_parent().add_child(bullet)
		await get_tree().create_timer(0.5).timeout
		
		shoot_cd = false
	
func _on_agro_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerAgro =  true
		player = body

func _on_agro_box_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerAgro =  false
		player = null
