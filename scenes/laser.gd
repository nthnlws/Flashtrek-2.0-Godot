extends RayCast2D

var laserClickState:bool= false # Bool to check input hold status
var target_shield # Stores ID of the target shield to check status later
var enemy_collision:bool = false # Bool to check if Raycast is hitting one of desired target areas
var laserStatus:bool = false # Final variable created after switching laser on or off
var cast_point:Vector2 # Coords of where Line2D will cast to, result of Raycast logic
var cast_point_exact:Vector2 # Coords of exact collision for use in particles
var fizzlePlayed:bool

@onready var ship_particles = $ship_particles
@onready var collision_particles = $collision_particles


var collision_area # Global variable for HUD and debug

@export var default_damage:int = 20
var damage_rate:int = default_damage
@export var view_distance:int = 1200

func _ready():
	GameSettings.laserRange = view_distance
	$Line2D.visible = false
	$Line2D.width = 0
	$Line2D.points[1] = Vector2.ZERO
	target_position = Vector2(0, -view_distance)
	ship_particles.emitting = false
	
	
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
		if collider.is_in_group("player"):
			add_exception(collider)
		if laserClickState == true:
			if collider.name == "shield_area":
				enemy_collision = true
				target_shield = collider
				if target_shield.get_parent().shieldActive == true:
					cast_point = to_local(get_collision_point())
					cast_point_exact = cast_point
					collider.get_parent().sp_current -= damage_rate*delta
					collision_particles.process_material.color = Color(0.5, 3.0, 6.0, 1.0)
				if target_shield.get_parent().shieldActive == false:
					add_exception(target_shield)
			elif collider.name == "Hitbox":
				enemy_collision = true
				cast_point = to_local(collider.global_position)
				cast_point_exact = to_local(get_collision_point())
				collider.get_parent().hp_current -= damage_rate*delta
				collision_particles.process_material.color = Color(1.0, 1.0, 0.0, 1.0)
				clear_exceptions()
	else:
		enemy_collision = false
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
		if get_parent().warping_active == false:
			laserClickState = true
			
	#Turns off laser if right click is released or player is warping
	if Input.is_action_just_released("shoot_laser") or get_parent().warping_active == true or get_parent().energy_current <= 0:
		laserClickState = false
	
	#State Logic Machine for laser status
	if laserClickState == true && enemy_collision == true:
		collision_particles.position = cast_point_exact
		collision_particles.global_rotation = get_collision_normal().angle()
		if laserStatus == false:
			laserOn()
	elif enemy_collision == false or laserClickState == false:
		if laserStatus == true:
			laserOff()
	elif enemy_collision == false && laserClickState == false:
		if laserStatus == true:
			laserOff()
	
	
	#Laser fizzle sound
	if Input.is_action_just_pressed("shoot_laser"):
		if get_parent().warping_active == false:
			await get_tree().process_frame
			await get_tree().process_frame
			if enemy_collision == false:
				$laserFizzle.play()
		

	#Ship laser particles
	if laserClickState == true && get_parent().warping_active == false:
		ship_particles.emitting = true
	else:
		ship_particles.emitting = false
	
func laserOn(): 
	$Line2D.visible = true
	$laser_particles.emitting = true
	var tween = create_tween()
	tween.tween_property($Line2D, "width", 5, 0.1)
	laserStatus = true
	collision_particles.emitting = true
	$laserSound.play()
	
func laserOff(): 
	var tween = create_tween()
	tween.tween_property($Line2D, "width", 0, 0.1)
	await tween.finished
	$Line2D.visible = false
	$laser_particles.emitting = false
	laserStatus = false
	collision_particles.emitting = false
	$laserSound.stop()
	
