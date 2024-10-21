extends CharacterBody2D

signal exploded(pos, size, points)
signal player_collision(Area: Area2D)

@export var AI_enabled:bool = true
@export var default_speed:int = 50
@export var torpedo: PackedScene
@export var shieldScene: PackedScene

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
var bullet_life:float
var predicted_position
var angle_diff # Angle between current rotation and target angle
	
func _ready() -> void:
	#Sets bullet speed for use in targeting calculation
	var torpedo_scene = torpedo.instantiate()
	bullet_speed = torpedo_scene.speed
	bullet_life = torpedo_scene.lifetime
	
	#Sets targets for movement if AI is enabled
	if AI_enabled:
		starbase = get_node("/root/Game/Level/Starbase")
		LevelData.enemies.append(self)
	elif AI_enabled == false:
		$AgroBox.queue_free()
		
	if GameSettings.enemyShield == true:
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
		playerMovement(delta)
		moveTarget = "Player"
	elif !player and returnToStarbaseBool == false: # Movement toward picked planet
		planetMovement(delta)
		moveTarget = "Planet"
	elif !player and returnToStarbaseBool == true:
		starbaseMovement(delta)
		moveTarget = "Starbase"
	elif global_position - starbase.global_position < 1500:
		returnToStarbaseBool = false
		selectRandomPlanet()

	else: print("No matching movement status")
	move_and_slide()


func selectRandomPlanet():
	endPoint = LevelData.planets.pick_random().global_position

	
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
	var rotation_speed: float = 3.0 * delta
	angle_diff = wrapf(angle - self.global_rotation, -PI, PI)
	
	rotation = lerp_angle(self.global_rotation, angle, min(rotation_speed / abs(angle_diff), 1))
	
	if targetName == "Player":
		velocity = (targetPos - self.global_position).normalized()*speed
	elif targetName == "Starbase":
		velocity = (targetPos - self.global_position).normalized()*speed
	elif targetName == "Planet":
		velocity = (targetPos - self.global_position).normalized()*speed
		
	move_and_slide()
	return angle_diff

func explode():
	LevelData.enemies.erase(self)
	self.queue_free()

func _on_hitbox_area_entered(area):
	if area.is_in_group("projectile") and area.shooter != "enemy":
		$TorpedoHit.play()
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
		return predicted_position
	else: #No firing solution possible
		predicted_position = player.global_position
		return player.global_position

func playerMovement(delta):
	predict_player_position()
	if typeof(predicted_position) != TYPE_VECTOR2:
		moveToTarget("Player", player.global_position, delta)
		#print("player pos: " + str(moveToTarget("Player", player.global_position, delta)))
	else:
		moveToTarget("Player", predicted_position, delta)
		#print("Predicted: " + str(moveToTarget("Player", predicted_position, delta)))
	
	#var angle_diff = moveToTarget("Player", predicted_position, delta)
	print(angle_diff)
	if abs(angle_diff) < TAU/12:
		shoot_bullet()


func calculate_shooting_angle():
	if typeof(predicted_position) != TYPE_VECTOR2:
		return null # No valid firing solution
	
	else:
		var delta_x = predicted_position.x - self.global_position.x
		var delta_y = predicted_position.y - self.global_position.y

		# Calculate the angle using atan2
		var shooting_angle = atan2(delta_y, delta_x)

		return shooting_angle
	
	
func shoot_bullet():# Instantiate and configure bullet
	var angle = calculate_shooting_angle()
	if angle != null:
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
		angle_diff = TAU
