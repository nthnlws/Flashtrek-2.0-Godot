extends RayCast2D

var laserClickState:bool= false # Bool to check input hold status
var target_shield # Stores ID of the target shield to check status later
var enemy_collision:bool = false # Bool to check if Raycast is hitting one of desired target areas
var laserStatus:bool = false # Final variable created after switching laser on or off
var cast_point:Vector2 # Coords of where Line2D will cast to, result of Raycast logic

var collision_area # Global variable for HUD and debug

@export var damage_rate:int = 20
@export var view_distance:int = 1200

func _ready():
	$Line2D.visible = false
	$Line2D.width = 0
	$Line2D.points[1] = Vector2.ZERO
	target_position = Vector2(0, -view_distance)
	
	
func _physics_process(delta):
	force_raycast_update()
	if is_colliding():
		var collider: = get_collider()
		collision_area = collider
		if collider.is_in_group("player"):
			add_exception(collider)
		if laserClickState == true:
			if collider.name == "shield_area":
				print(collider.name)
				enemy_collision = true
				target_shield = collider
				if target_shield.get_parent().shieldActive == true:
					cast_point = to_local(get_collision_point())
					collider.get_parent().sp_current -= damage_rate*delta
				if target_shield.get_parent().shieldActive == false:
					add_exception(target_shield)
			elif collider.name == "Hitbox":
				print("hitbox")
				enemy_collision = true
				if target_shield.get_parent().shieldActive == true:
					clear_exceptions()
					return
				else:
					cast_point = to_local(collider.global_position)
					collider.get_parent().hp_current -= damage_rate*delta
	else:
		enemy_collision = false
		cast_point = Vector2(0, -view_distance)
	$Line2D.points[1] = cast_point
	
	
func _process(delta):
	#Turns on laser if player is right clicking and not warping
	if Input.is_action_just_pressed("shoot_laser"):
		if get_parent().warping_active == false:
			#set_physics_process(true)
			laserClickState = true
			
	#Turns off laser if right click is released or player is warping
	if Input.is_action_just_released("shoot_laser") or get_parent().warping_active == true or get_parent().energy_current <= 0:
		laserClickState = false
		#set_physics_process(false)
	
	#State Logic Machine for laser status
	if laserClickState == true && enemy_collision == true:
		if laserStatus == false:
			laserOn()
	elif enemy_collision == false or laserClickState == false:
		if laserStatus == true:
			laserOff()
	elif enemy_collision == false && laserClickState == false:
		if laserStatus == true:
			laserOff()
	
func laserOn(): 
	$Line2D.visible = true
	var tween = create_tween()
	tween.tween_property($Line2D, "width", 5, 0.1)
	laserStatus = true
	
func laserOff():
	var tween = create_tween()
	tween.tween_property($Line2D, "width", 0, 0.1)
	await tween.finished
	$Line2D.visible = false
	laserStatus = false
