extends RayCast2D

var laserClickState:bool= false # Bool to check input hold status
var enemy_collision:bool = false # Bool to check if Raycast is hitting one of desired target areas
var laserStatus:bool = false # Final variable created after switching laser on or off
var cast_point:Vector2 # Coords of where Line2D will cast to, result of Raycast logic
var cast_point_exact:Vector2 # Coords of exact collision for use in particles
var fizzlePlayed:bool

@onready var ship_particles = $ship_particles
@onready var collision_particles = $collision_particles
@onready var hitbox = get_parent().get_node("Hitbox")
@onready var shield = get_parent().get_node("playerShield").get_node("shield_area")

var shield_exception # Node to add and remove to exception list
var collision_area # Global variable for HUD and debug

@export var default_damage:int = 20
var damage_rate:int = default_damage
@export var view_distance:int = 1200

func _ready():
	#Adds own player areas to exception list
	add_exception(hitbox)
	add_exception(shield)
	
	GameSettings.laserRange = view_distance
	GameSettings.laserDamage = default_damage
	$Line2D.visible = false
	$Line2D.width = 0
	$Line2D.points[1] = Vector2.ZERO
	target_position = Vector2(0, -view_distance)
	
	
func _physics_process(delta):
	force_raycast_update()
	
	# Laser range override from options menu
	if GameSettings.laserRangeOverride == true:
		target_position = Vector2(0, -GameSettings.laserRange)
	elif GameSettings.laserRangeOverride == false:
		target_position = Vector2(0, -view_distance)

	# Collision logic
	if is_colliding():
		var collider: = get_collider()
		collision_area = collider
		
		if collider.is_in_group("enemy_shield"):
			var target_shield = collider
			shield_exception = collider
			if target_shield.get_parent().shieldActive == true:
				cast_point = to_local(get_collision_point())
				cast_point_exact = cast_point
				target_to_shield(collider, delta)
				laserOn()
			elif target_shield.get_parent().shieldActive == false:
				add_exception(target_shield)
		elif collider.is_in_group("enemy_hitbox"):
			cast_point = to_local(collider.global_position)
			cast_point_exact = to_local(get_collision_point())
			target_to_hitbox(collider, delta)
			laserOn()
	else:
		enemy_collision = false
		laserOff()
	$Line2D.points[1] = cast_point
	
	#Particles for laser beam path
	$laser_particles.position = cast_point * 0.5
	$laser_particles.process_material.emission_box_extents.y = cast_point.length() * 0.5
	
func _process(delta):
	# Damage setting from Cheat Menu
	if GameSettings.laserDamageOverride == true:
		damage_rate = GameSettings.laserDamage
	else:
		damage_rate = default_damage
	
	#Turns on laser if player is right clicking and not warping
	if Input.is_action_just_pressed("shoot_laser"):
		if get_parent().warping_active == false && GameSettings.menuStatus == false:
			laserClickState = true
			ship_particles.emitting = true
			
	#Turns off laser if right click is released or player is warping
	if Input.is_action_just_released("shoot_laser") or get_parent().warping_active == true or get_parent().energy_current <= 0 or GameSettings.menuStatus == true:
		laserClickState = false
		ship_particles.emitting = false
		laserOff()


	#Laser fizzle sound
	if Input.is_action_just_pressed("shoot_laser"):
		if laserClickState == true:
			await get_tree().process_frame
			await get_tree().process_frame
			if enemy_collision == false:
				$laserFizzle.play()
		
		
func target_to_shield(collider, delta):
	enemy_collision = true
	
	#Sets collision particle position and color
	collision_particles.process_material.color = Color(0.5, 3.0, 6.0, 1.0) #Color to blue
	collision_particles.position = cast_point_exact
	collision_particles.global_rotation = get_collision_normal().angle()
	
	if laserStatus == true:
		collider.get_parent().sp_current -= damage_rate*delta
	
func target_to_hitbox(collider, delta):
	enemy_collision = true
	
	##Sets collision particle position and color
	collision_particles.process_material.color = Color(1.0, 1.0, 0.0, 1.0) #Color to yellow
	collision_particles.position = cast_point_exact
	collision_particles.global_rotation = get_collision_normal().angle()

	
	#Clears exception before next phyics update in case shield regens
	if shield_exception != null:
		remove_exception(shield_exception)
	
	if laserStatus == true:
		collider.get_parent().hp_current -= damage_rate*delta
	
	
func laserOn():
	if laserClickState == true && enemy_collision == true && laserStatus == false:
		#Turns on collision particles on target contact point
		collision_particles.emitting = true
		
		#Turn on laser beam
		$Line2D.visible = true
		$laser_particles.emitting = true
		var tween = create_tween()
		tween.tween_property($Line2D, "width", 5, 0.1)

		$laserSound.play()
		$laserBass.play()
		$laserBass2.play()

		laserStatus = true
	
func laserOff(): 
	if laserStatus == true:
		#Turns off laser beam
		var tween = create_tween()
		tween.tween_property($Line2D, "width", 0, 0.1)
		await tween.finished
		$Line2D.visible = false
		$laser_particles.emitting = false
		
		collision_particles.emitting = false
		
		$laserSound.stop()
		$laserBass.stop()
		$laserBass2.stop()
		
		laserStatus = false
	
