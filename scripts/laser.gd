extends RayCast2D

var accumulated_damage:float = 0
var accumulated_time:float = 0

var laserClickState:bool= false # Bool to check input hold status
var enemy_collision:bool = false # Bool to check if Raycast is hitting one of desired target areas
var laserStatus:bool = false # Final variable created after switching laser on or off
var cast_point_exact:Vector2 # Coords of exact collision for use in particles

@onready var parent = get_parent()
@onready var ship_particles = $ship_particles
@onready var collision_particles = $collision_particles

var shield_exception # Node to add and remove to exception list
var collision_area # Global variable for HUD and debug


#var accumulated_damage: float = 0
@export var base_damage:int = 20
var damage:float = 20:
	get:
		return PlayerUpgrades.DamageAdd + (base_damage * PlayerUpgrades.DamageMult)
		

@export var view_distance:int = 1200

@export var base_energy_drain:float = 7.5
var energy_drain: float = 7.5:
	get:
		return PlayerUpgrades.EnergyDrainAdd + (base_energy_drain * PlayerUpgrades.EnergyDrainMult)


func _ready():
	#Adds own player areas to exception list
	add_exception(get_parent().get_node("Hitbox"))
	add_exception(get_parent().get_node("playerShield/shield_area"))
	
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
				cast_point_exact = to_local(get_collision_point())
				$Line2D.points[1] = cast_point_exact
				target_to_shield(collider, delta)
				laserOn()
			elif target_shield.get_parent().shieldActive == false:
				add_exception(target_shield)
		elif collider.is_in_group("enemy_hitbox"):
			cast_point_exact = to_local(get_collision_point())
			$Line2D.points[1] = cast_point_exact
			target_to_hitbox(collider, delta)
			laserOn()
	else:
		enemy_collision = false
		laserOff()
		
	
	#Particles for laser beam path
	$laser_particles.position = cast_point_exact * 0.5
	$laser_particles.process_material.emission_box_extents.y = cast_point_exact.length() * 0.5
	
func _process(delta):
	# Damage setting from Cheat Menu
	if GameSettings.laserDamageOverride == true:
		damage = GameSettings.laserDamage
	else:
		damage = damage
	
	#Turns on laser if player is right clicking and not warping
	if Input.is_action_just_pressed("right_click"):
		if get_parent().warping_active == false and GameSettings.menuStatus == false:
			laserClickState = true
			ship_particles.emitting = true
			
	#Turns off laser if right click is released or player is warping
	if Input.is_action_just_released("right_click") or get_parent().warping_active == true or get_parent().energy_current <= 0 or GameSettings.menuStatus == true:
		laserClickState = false
		ship_particles.emitting = false
		laserOff()

	if laserStatus == true:
		accumulated_damage += damage * delta
		accumulated_time += delta
		if accumulated_time > 0.5:
			parent.create_damage_indicator(snappedf(accumulated_damage, 0.5), to_global(cast_point_exact), Utility.damage_blue)
			accumulated_damage = 0
			accumulated_time = 0

	#Laser fizzle sound
	if Input.is_action_just_pressed("right_click"):
		if laserClickState == true:
			await get_tree().process_frame
			await get_tree().process_frame
			if enemy_collision == false:
				$laserFizzle.play()
		
		
func target_to_shield(collider, delta):
	enemy_collision = true
	
	#Sets collision particle position and color
	collision_particles.process_material.color = Color(0.5, 1.0, 1.0, 1.0) #Color to blue
	collision_particles.position = cast_point_exact
	collision_particles.global_rotation = get_collision_normal().angle()
	
	if laserStatus == true:
		collider.get_parent().sp_current -= damage*delta
	
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
		var frame_damage = damage*delta
		collider.get_parent().hp_current -= frame_damage
	
	
func laserOn():
	if laserClickState == true and enemy_collision == true and laserStatus == false:
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
	
