extends CharacterBody2D
class_name Player

# --- Components ---
@onready var energy: EnergyComponent = $EnergyComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var stats: PlayerUpgrades = PlayerUpgrades.new()

# --- Node References ---
@onready var sprite: Sprite2D = $ShipSprite
@onready var cloak_anim: AnimationPlayer = $ShipSprite/CloakAnim
@onready var shield: Shield = $Shield
@onready var muzzle: Node2D = $Muzzle
@onready var laser: Laser = $Laser
@onready var tractor_beam: TractorBeam = $TractorBeam
@onready var camera: Camera2D = $Camera2D
@onready var galaxy_particles: GPUParticles2D = $GalaxyParticles
@onready var galaxy_warp_sound: AudioStreamPlayer = %Galaxy_warp

# --- Exported Scenes ---
@export var torpedo_scene: PackedScene
@export var missile_scene: PackedScene

# --- Movement Variables ---
var direction: Vector2 = Vector2.ZERO
var overdrive_active: bool = false
var overdrive_multiplier: float = 0.45
var overdrivem_r: float = 1.0
var overdrivem_v: float = 1.0
var trans_length: float = 0.8
var base_scale: Vector2 = Vector2(1.5, 1.5)

# --- State Variables ---
var shoot_cd: bool = false
var shooting_button_held: bool = false
var cloaked: bool = false
var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
var current_cargo: int = 0
var current_tweens: Array[Tween] = []

# --- Getters for Stat Application ---
var max_speed: float:
	get: return 750.0 * stats.SpeedMult
var rotation_speed: float:
	get: return 150.0 * stats.RotateMult
var acceleration: float:
	get: return 6.5 * stats.AccelMult
var rate_of_fire: float:
	get: return 5.0 * stats.FireRateMult
var warp_range: int:
	get: return 20 + stats.WarpRangeAdd
var cargo_capacity: int:
	get: return 1 + stats.CargoCapacityAdd

# Cargo upgrade variables
@export var base_cargo_size: int = 1:
	get:
		return base_cargo_size + stats.CargoCapacityAdd

func set_player_direction(joystick_direction) -> void:
	direction = joystick_direction


func _ready() -> void:
	z_index = Utility.Z["Player"]
	$warp_anim.z_index = Utility.Z["Effects"] 
	sprite.material.set("shader_parameter/flash_value", 0.0)
	
	_connect_signals()
	_sync_data_to_resource(Utility.starting_ship)
	_sync_stats_to_resource(Utility.starting_ship)
	
	energy.max_energy = energy.max_energy * stats.EnergyCapacityMult
	energy.max_energy_changed.connect(func(val): SignalBus.playerMaxEnergyChanged.emit(val))
	energy.energy_changed.connect(func(val): SignalBus.playerEnergyChanged.emit(val))
	
	_set_ship_scale(Vector2(1.5, 1.5))
	
	for weapon in get_tree().get_nodes_in_group("secondary_weapon"):
		weapon.faction = faction


func _connect_signals() -> void:
	SignalBus.player_type_changed.connect(_sync_data_to_resource)
	SignalBus.player_type_changed.connect(_sync_stats_to_resource)
	MissionManager.mission_started.connect(_handle_mission_pickup)
	MissionManager.mission_completed.connect(_handle_mission_finish)
	SignalBus.joystickMoved.connect(set_player_direction)
	SignalBus.teleport_player.connect(teleport)
	SignalBus.TopLeft_clicked.connect(trigger_warp)
	SignalBus.triggerGalaxyWarp.connect(galaxy_warp_out)
	
	tractor_beam.object_captured.connect(_handle_container_pickup)


func _sync_data_to_resource(ship:Utility.SHIP_TYPES) -> void:
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[ship]
	
	sprite.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
	shield.scale = Vector2(float(ship_data.SHIELD_SCALE_X), float(ship_data.SHIELD_SCALE_Y)) * base_scale
	muzzle.position = Vector2(0, ship_data.MUZZLE_POS)
	muzzle.position.y = ship_data.MUZZLE_POS * base_scale.y
	
	var rawColl = ship_data.COLLISION_POLY
	var parsed_array = JSON.parse_string(rawColl)
	var PV2Array = PackedVector2Array()
	for pair in parsed_array:
		PV2Array.append(Vector2(pair[0], pair[1]))
	PV2Array = center_polygon(PV2Array)
	$hitbox_area/CollisionPolygon2D.polygon = PV2Array
	$WorldCollisionShape.polygon = PV2Array


func _sync_stats_to_resource(ship:Utility.SHIP_TYPES) -> void:
	var ship_stats:Dictionary = Utility.PLAYER_SHIP_STATS.values()[ship]
	
	max_speed = ship_stats.SPEED
	rotation_speed = ship_stats.ROTATION_SPEED
	base_cargo_size = ship_stats.CARGO_SIZE
	health_component.HP_max = ship_stats.MAX_HP
	health_component.SP_max = ship_stats.MAX_SHIELD


func center_polygon(points: Array) -> PackedVector2Array:
	var min_x = points[0].x
	var max_x = points[0].x
	var min_y = points[0].y
	var max_y = points[0].y

	# Find bounds
	for p in points:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var center_x = (min_x + max_x) / 2.0
	var center_y = (min_y + max_y) / 2.0

	var adjusted_points = []
	for p in points:
		var centered = Vector2(p.x - center_x, p.y - center_y)
		var shifted = centered + Vector2(0, -2) # Manual adjustment to center points on ship
		adjusted_points.append(shifted)

	return PackedVector2Array(adjusted_points)


func _set_ship_scale(new_scale: Vector2) -> void:
	base_scale = new_scale
	shield.scale *= new_scale
	sprite.scale *= new_scale
	$hitbox_area.scale *= new_scale
	$WorldCollisionShape.scale *= new_scale
	muzzle.position.y *= new_scale.y


func _process(delta: float) -> void:
	if !health_component.alive: return
	
	# Handle Idle Audio
	var is_moving: bool = velocity.length() > 100.0 and Utility.current_gamestate == Utility.GAMESTATE.WARPING
	idle_sound(is_moving)
	
	if !laser.laser_on:
		energy.regenerate(delta, 10.0)


func _unhandled_input(event: InputEvent) -> void:
	# Primary weapon firing
	if event.is_action_pressed("left_click"):
		shooting_button_held = true
	if event.is_action_released("left_click"):
		shooting_button_held = false
	
	if event.is_action_pressed("right_click"):
		#shoot_missile(get_global_mouse_position())
		tractor_beam.visible = true
		tractor_beam.try_activate_beam()
	
	if event.is_action_released("right_click"):
		tractor_beam.visible = false
		tractor_beam.deactivate_beam()
	# Secondary weapon firing
	#if event.is_action_pressed("right_click"):
		#if _can_fire_weapons(laser.energy_drain):
			#laser.firing_button_held = true
	#if event.is_action_released("right_click"):
		#laser.firing_button_held = false
		#laser.stop_firing()


func _physics_process(delta: float) -> void:
	if !health_component.alive or GameSettings.menuStatus: return
	
	_handle_input_actions()
	_handle_movement(delta)
	move_and_slide()


func _handle_input_actions() -> void:
	if Input.is_action_just_pressed("overdrive") and Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		overdrive_state_change("SMOOTH")

	if Input.is_action_pressed("left_click") and !shoot_cd and !overdrive_active:
		shoot_torpedo()


func _handle_movement(delta: float) -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
	# Check for keyboard input (Windows) and add to direction
		if OS.get_name() == "Windows":
			direction.x = Input.get_axis("move_backward", "move_forward")  # Forward/backward movement

		# Add joystick direction for Android or hybrid control
		#direction += direction
		#print(direction)
		# Apply forward/backward thrust logic
		if direction.x != 0:
			velocity += Vector2(direction.x, 0).rotated(rotation) * acceleration / overdrivem_v
			velocity = velocity.limit_length(max_speed/overdrivem_v)
		else:
			# Gradually slow down when no input
			velocity = velocity.move_toward(Vector2.ZERO, 3)
			
		if direction.y !=0:
			rotate(deg_to_rad(direction.y * rotation_speed * delta * overdrivem_v))
		
		# Handle rotation for keyboard input
		if OS.get_name() == "Windows":
			if Input.is_action_pressed("rotate_right"):
				rotate(deg_to_rad(rotation_speed * delta * overdrivem_r))
			if Input.is_action_pressed("rotate_left"):
				rotate(deg_to_rad(-rotation_speed * delta * overdrivem_r))


func overdrive_state_change(speed) -> void: # Reverses overdrive state
	# Stop any ongoing tweens
	for tween:Tween in current_tweens:
		if tween.is_running():
			tween.stop()

	current_tweens.clear()  # Clear the list of running tweens
	
	if overdrive_active: # Transition to impulse
		energy.lock_regeneration(trans_length / 2)
		overdrive_active = false
		if laser:
			laser.force_enable()
		match speed:
			"INSTANT":
				scale = base_scale
				overdrivem_v = 1.0
				overdrivem_r = 1.0
				shield.call_deferred("fadein_SMOOTH")
			"SMOOTH":
				var tween_scale: Object = create_tween() # Ship sprite scale
				tween_scale.tween_property(self, "scale", base_scale, trans_length)
				current_tweens.append(tween_scale)
				
				var tween_v: Object = create_tween() # Max Velocity
				tween_v.tween_property(self, "overdrivem_v", 1.0, trans_length*4)
				current_tweens.append(tween_v)
				
				var tween_r: Object = create_tween() # Rotation speed
				tween_r.tween_property(self, "overdrivem_r", 1.0, trans_length)
				current_tweens.append(tween_r)
				
				shield.fadein_SMOOTH()
				overdrive_sound_off()
	else: # Transition to overdrive
		overdrive_active = true
		overdrive_sound_on()
		if laser:
			laser.force_disable()
		match speed:
			"INSTANT":
				scale = base_scale * Vector2(1.5, 1.0)
				overdrivem_v = overdrive_multiplier
				overdrivem_r = overdrive_multiplier
				shield.fadeout_INSTANT()
			"SMOOTH":
				var tween_scale: Object = create_tween() # Ship sprite scale
				tween_scale.tween_property(self, "scale", base_scale * Vector2(1.5, 1), trans_length)
				current_tweens.append(tween_scale)
				
				var tween_v: Object = create_tween() # Max Velocity
				tween_v.tween_property(self, "overdrivem_v", overdrive_multiplier, trans_length)
				current_tweens.append(tween_v)
				
				var tween_r: Object = create_tween() # Rotation speed
				tween_r.tween_property(self, "overdrivem_r", overdrive_multiplier, trans_length)
				current_tweens.append(tween_r)
				
				shield.fadeout_SMOOTH()


func shoot_torpedo() -> void:
	var bullet: Torpedo = torpedo_scene.instantiate()
	var cost: float = bullet.energy_drain

	if _can_fire(cost):
		energy.consume(cost)
		energy.lock_regeneration(0.5)
		shoot_cd = true
		
		bullet.position = muzzle.global_position
		bullet.rotation = rotation
		bullet.shooterObject = self
		bullet.damage *= stats.DamageMult
		bullet.faction = faction
		
		bullet.exceptions.append($hitbox_area)
		bullet.exceptions.append(shield.get_node("shield_area"))
		
		$Projectiles.add_child(bullet)
		%HeavyTorpedo.pitch_scale = randf_range(0.95, 1.05)
		%HeavyTorpedo.play()
		
		get_tree().create_timer(1.0 / rate_of_fire).timeout.connect(func(): shoot_cd = false)
	else:
		bullet.queue_free()


func shoot_missile(clicked_pos:Vector2) -> void:
	var missile: HomingMissile = missile_scene.instantiate()
	var cost: float = missile.energy_drain
	
	if _can_fire(cost):
		missile.position = muzzle.global_position
		missile.rotation = self.rotation
		missile.exceptions.append($hitbox_area)
		missile.exceptions.append(shield.get_node("shield_area"))
		missile.shooterObject = self
		energy.consume(cost)
		energy.lock_regeneration(1.0)
		missile.max_damage = missile.max_damage * stats.DamageMult
		missile.faction = self.faction
		missile.target_position = clicked_pos
		
		%HeavyTorpedo.pitch_scale = randf_range(0.95, 1.05)
		%HeavyTorpedo.play()
		$Projectiles.add_child(missile)
	else:
		missile.queue_free()


func _can_fire(cost: float) -> bool:
	return (
		energy.current_energy >= cost and 
		!overdrive_active and 
		!cloaked and 
		Utility.current_gamestate != Utility.GAMESTATE.WARPING
	)


func killPlayer(hit_event:HitEvent) -> void:
	Utility.current_gamestate = Utility.GAMESTATE.SYSTEM
	%PlayerDieSound.play()
	self.visible = false
	shield.fadeout_INSTANT()
	
	if overdrive_active == true:
		overdrive_state_change("INSTANT")
	
	#Kill player stats
	energy.energy_current = 0
	
	await get_tree().create_timer(1.5).timeout
	SignalBus.playerDied.emit()


func respawn(pos: Vector2) -> void:
	if health_component.alive == false:
		health_component.alive = true
		SignalBus.playerRespawned.emit()
		
		global_position = pos
		velocity = Vector2.ZERO
		self.visible = true
		
		# Restores all HUD values to max
		health_component.hp_current = health_component.HP_max #Resets HP to max
		health_component.sp_current = health_component.SP_max #Resets Shield
		energy.energy_current = energy.max_energy #Resets energy
		
		rotation = deg_to_rad(-90.0) #Sets rotation to up
		
		shield.turnShieldOn()
		health_component.regenTimeout = false


func teleport(new_position:Vector2) -> void: # Uses coords from cheat menu to teleport player
	global_position = new_position
	velocity = Vector2(0, 0)
	if overdrive_active == true:
		overdrive_state_change("INSTANT")


#Audio functions
# Movement
func overdrive_sound_on() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(%ship_idle, "volume_db", -60, 2.0) # Reduces idle sound volume
	%overdrive_on.play()


func overdrive_sound_off() -> void:
	%overdrive_off.play()


func idle_sound(active: bool) -> void:
	if overdrive_active == true:
		#$ship_idle.stop()
		pass
	elif %ship_idle.playing == false:
		%ship_idle.play()
	elif %ship_idle.playing == true:
		if active == false:
			var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(%ship_idle, "volume_db", -25, 2.0)
		elif active == true:
			var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(%ship_idle, "volume_db", -15, 2.0)


func velocity_check() -> bool:
	# Check velocity warp criteria
	var base_check = (
		Utility.current_gamestate != Utility.GAMESTATE.WARPING and
		velocity.x > -100 and velocity.x < 100 and
		velocity.y > -100 and velocity.y < 100 and
		!overdrive_active
	)
	
	if not base_check:
		return false
	else: return true


func trigger_warp() -> void:
	if LevelManager.current_system_data.system_name != LevelManager.target_system_data.system_name:
		var start_sys_id:int = LevelManager.current_system_data.system_index
		var end_sys_id:int = LevelManager.target_system_data.system_index
		var warp_distance:int = GalaxyData.get_jump_distance(start_sys_id, end_sys_id)
		if  warp_distance > warp_range:
			var error_message: String = "Max warp range of %s systems" % LevelManager.instance.player.warp_range
			SignalBus.changePopMessage.emit(error_message)
			return
		if !velocity_check():
			var error_message: String = "Must be stationary and in impulse to warp"
			SignalBus.changePopMessage.emit(error_message)
			return
		if warp_distance == -1:
			var error_message: String = "You must select a destination system"
			SignalBus.changePopMessage.emit(error_message)
			return
		elif warp_distance == -2:
			var error_message: String = "Warp destination must not be same as current system"
			SignalBus.changePopMessage.emit(error_message)
			return
		else:
			galaxy_warp_out()


func galaxy_warp_out() -> void:
	SignalBus.entering_galaxy_warp.emit()
	Utility.current_gamestate = Utility.GAMESTATE.WARPING
	
	self.velocity = Vector2.ZERO
	
	LevelManager.entry_coords = SystemData.get_entry_point(self.global_rotation)
	
	galaxy_warp_sound.play()
	await get_tree().create_timer(1.5).timeout
	shield.fadeout_SMOOTH()
	
	await get_tree().create_timer(0.5).timeout # 2 sec
	
	# Velocity tween
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "velocity", Vector2(2500, 0).rotated(rotation), 8.0)
	
	
	await get_tree().create_timer(1.0).timeout # 3.0 sec
	#Camera Zoom out
	create_tween().tween_property(camera, "zoom", Vector2(0.4, 0.4), trans_length / overdrive_multiplier * 3)
	
	await get_tree().create_timer(1.5).timeout # 4.5 sec
	galaxy_particles.emitting = true
	create_tween().tween_property(galaxy_particles, "amount_ratio", 1.0, 8.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(1.5).timeout # 6.0 sec
	#print("flat, scale")
	create_tween().tween_property(galaxy_particles.process_material, "flatness", 0.0, 5.0)
	create_tween().tween_property(galaxy_particles.process_material, "scale_min", 1.0, 3.5)
	create_tween().tween_property(galaxy_particles.process_material, "scale_max", 2.0, 3.5)
	
	await get_tree().create_timer(2.5).timeout # 8.5 sec
	var tween2: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween2.tween_property(galaxy_warp_sound, "pitch_scale", 2.5, 3.5)
	
	await get_tree().create_timer(2.5).timeout
	cloak_ship(3.0, false)
	
	await get_tree().create_timer(1.0).timeout #11.5 sec, velocity tween ends
	#create_tween().tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.8)
	create_tween().tween_property(galaxy_particles, "amount_ratio", 0.0, 2.5)
	
	
	await get_tree().create_timer(0.30).timeout
	%warp_boom.play()
	
	await get_tree().create_timer(0.20).timeout
	galaxy_warp_sound.stop()
	
	# Camera zoom in
	var tween3: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween3.tween_property(camera, "zoom", Vector2(2.75, 2.75), 3.0)
	
	
	SignalBus.galaxy_warp_screen_fade.emit()
	galaxy_warp_sound.pitch_scale = 1.0
	tween.stop()
	tween2.stop()
	tween3.stop()


func _handle_mission_pickup(mission_data:MissionData) -> void:
	current_cargo += 1


func apply_upgrade(pickup: UpgradePickup) -> void:
	SignalBus.playerUpgradeApplied.emit(pickup.upgrade_type)
	var mult_step:float = 0.05 # 5% increase to stat
	
	var type: UpgradePickup.MODULE_TYPES = pickup.upgrade_type
	var modifier: UpgradePickup.MODIFIER = pickup.modifier_type
	
	match type:
		UpgradePickup.MODULE_TYPES.SPEED:
			stats.SpeedMult = stats.SpeedMult + mult_step
		UpgradePickup.MODULE_TYPES.ROTATION:
			stats.RotateMult = stats.RotateMult + mult_step
		UpgradePickup.MODULE_TYPES.FIRE_RATE:
			stats.FireRateMult = stats.FireRateMult + mult_step
		UpgradePickup.MODULE_TYPES.HEALTH:
			stats.HullMult = health_component.stats.HullMult + mult_step
		UpgradePickup.MODULE_TYPES.SHIELD:
			health_component.stats.ShieldMult = health_component.stats.ShieldMult + mult_step
			if shield: # Manually forces the shield to calculate and signal the new max value
				health_component.SP_max = health_component.SP_max
		UpgradePickup.MODULE_TYPES.DAMAGE:
			stats.DamageMult = stats.DamageMult + mult_step


func _handle_container_pickup(data:ContainerData) -> void:
	print('picked up container')
	if data.is_mission_goal == true:
		print('attempting mission finish')
		MissionManager.complete_mission()


func cloak_ship(length:float, show_shadow:bool = false) -> void:
	cloaked = true
	
	var cloak_shader = preload("res://resources/Materials_Shaders/cloak_CENTER.gdshader")
	var new_mat = ShaderMaterial.new()
	new_mat.shader = cloak_shader
	new_mat.resource_local_to_scene = true
	sprite.material = new_mat
	
	cloak_anim.speed_scale = 2/length
	cloak_anim.play("cloak")
	await cloak_anim.animation_finished
	
	if show_shadow:
		var cloak_fill:ShaderMaterial = preload("res://resources/Materials_Shaders/player_cloak_fill.tres")
		var new_mat2 = cloak_fill
		new_mat2.resource_local_to_scene = true
		sprite.material = new_mat2


func uncloak_ship(length:float) -> void:
	var cloak_shader = preload("res://resources/Materials_Shaders/cloak_CENTER.gdshader")
	var new_mat = ShaderMaterial.new()
	new_mat.shader = cloak_shader
	new_mat.resource_local_to_scene = true
	sprite.material = new_mat
	
	cloak_anim.speed_scale = 2/length
	cloak_anim.play("uncloak")
	await cloak_anim.animation_finished
	
	cloaked = false


func _handle_mission_finish(finished_data:MissionData) -> void:
	current_cargo -= 1
	current_cargo = clamp(current_cargo, 0, base_cargo_size)
