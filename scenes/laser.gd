extends RayCast2D

var laserState := false
var first_collision := false # Checks if a shield has been targeted yet
var target_shield # Stores ID of the target shield to check status later

func _ready():
	set_physics_process(false)
	$Line2D.visible = false
	$Line2D.width = 0
	$Line2D.points[1] = Vector2.ZERO
	target_position = Vector2(0, -600)
	
func _physics_process(delta):
	var cast_point := Vector2(0, -600)
	force_raycast_update()
	
	if is_colliding():
		var collider = get_collider()
		if collider.name == "shield_area":
			if first_collision == false:
				target_shield = collider
			first_collision = true
			if target_shield.get_parent().shieldActive == true:
				cast_point = to_local(get_collision_point())
			if target_shield.get_parent().shieldActive == false:
				add_exception(target_shield)
		if collider.name == "Hitbox":
			if target_shield.get_parent().shieldActive == true:
				clear_exceptions()
				return
			else:
				cast_point = to_local(collider.global_position)
		
	$Line2D.points[1] = cast_point
	
func _process(delta):
	#Turns on laser if player is right clicking and not warping
	if Input.is_action_just_pressed("shoot_laser"):
		if get_parent().warping_active == false:
			laserOn(true)

	#Turns off laser if right click is released or player is warping
	if Input.is_action_just_released("shoot_laser") or get_parent().warping_active == true:
		laserOn(false)

	
func laserOn(cast:bool) -> void:
	laserState = cast
	
	if laserState == true:
		appear()
	else:
		disappear()
	set_physics_process(laserState)
	
func appear():
	$Line2D.visible = true
	var tween = create_tween()
	tween.tween_property($Line2D, "width", 5, 0.1)

func disappear():
	var tween = create_tween()
	tween.tween_property($Line2D, "width", 0, 0.1)
	await tween.finished
	$Line2D.visible = false
