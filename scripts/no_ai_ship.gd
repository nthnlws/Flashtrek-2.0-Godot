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
var randomMove:bool = false
var enemyTarget:String

var player = null
var target
var shoot_cd:float = false
var rate_of_fire:float = 1.0
var bullet_speed = 300


func _process(delta: float) -> void:
	if player:
		fire_at_predicted_position()
	
	
func _physics_process(delta):

	# Movement state setter
	if playerAgro == true:
		playerMovement()
		enemyTarget = "Player"
	elif randomMove == true:
		randomMovement(endPoint)
		enemyTarget = "Random"
	#else: print("No matching movement status")

	move_and_slide()


func playerMovement():
	if player:
		var direction = global_position.direction_to(player.global_position) # Sets movement direction to player
		velocity = direction.normalized()*speed
		rotateToDirection(direction)
	
func randomMovement(endPoint): 
	var direction = global_position.direction_to(endPoint) # Sets movement direction to player
	velocity = direction.normalized()*speed
	rotateToDirection(direction)
	if self.global_position.distance_to(endPoint) < 5:
		randomMove = false
	
func rotateToDirection(target_direction: Vector2):
	var target_angle = atan2(target_direction.y, target_direction.x) + deg_to_rad(90)
	var difference = rotation - target_angle
	rotation = lerp_angle(rotation, target_angle, 0.1)

func explode():
	SignalBus.enemies.erase(self)
	self.queue_free()

func _on_hitbox_area_entered(area):
	if area.is_in_group("projectile") and area.shooter != "enemy":
		$TorpedoHit.play()
		area.queue_free()
		var damage_taken = area.damage
		hp_current -= damage_taken


func predict_player_position(player_pos: Vector2, player_velocity: Vector2, enemy_pos: Vector2, bullet_speed: float) -> Vector2:
	# Calculate the vector from the enemy to the player
	var to_player = player_pos - enemy_pos

	# Calculate the time it will take for the bullet to reach the player
	var time_to_impact = to_player.length() / 500

	# Predict the future position of the player
	var predicted_player_pos = player_pos + player_velocity * time_to_impact

	return predicted_player_pos

func fire_at_predicted_position():
	
	# Assume these values are provided or calculated elsewhere in your script
	var player_pos = target.global_position

	var player_velocity = target.velocity  # This should be the player's velocity vector
	#var bullet_speed = 300.0  # Set this to your bullet's speed
	var enemy_pos = global_position

	# Predict where the player will be
	var target_position = predict_player_position(player_pos, player_velocity, enemy_pos, bullet_speed)

	# Calculate the direction to shoot at
	var direction = enemy_pos.angle_to(target_position)
	#print(direction)

	# Shoot the bullet in that direction
	shoot_bullet(direction)

func shoot_bullet(direction: float):
	#print("shoot")
	# Instantiate and configure your bullet here
	var bullet = torpedo.instantiate()
	bullet.global_position = self.global_position
	bullet.rotation = self.rotation #direction
	#bullet.get_node("Sprite2D").rotation = deg_to_rad(180)
	bullet.shooter = "enemy"
	#velocity not needed as torpedo handles movement
	call_deferred("instantiate_bullet", bullet)


func instantiate_bullet(bullet):
	if !shoot_cd:
		shoot_cd = true
		get_parent().add_child(bullet)
		await get_tree().create_timer(0.5).timeout
		
		shoot_cd = false
	#print(bullet)
	
func _on_agro_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerAgro =  true
		player = body
		target = body
		fire_at_predicted_position()

func _on_agro_box_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		playerAgro =  false
		target = body
		player = null
