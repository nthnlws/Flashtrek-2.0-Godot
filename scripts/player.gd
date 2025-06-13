extends CharacterBody2D
class_name Player

@onready var intersection_line: Line2D = $intersection_line

var shoot_cd:bool = false
var shooting_button_held:bool = false # Variable to check if fire button is currently clicked

var alive: bool = true

var warping_active:bool = false
var shield_active:bool = false
var energyTime:bool = false
var warpTime:bool = false
var energy_regen_speed:int = 10

var trans_length:float = 0.8
var base_scale:Vector2 = Vector2(1.0, 1.0)
var direction:Vector2 = Vector2(0, 0)
var warp_multiplier:float = 0.45
var warpm_r:float = 1.0
var warpm_v:float = 1.0

var has_mission: bool = false
var current_mission: Dictionary = {}
var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
var animation_scale:Vector2 = Vector2(1, 1)

const WHITE_FLASH_MATERIAL: ShaderMaterial = preload("res://resources/Materials_Shaders/white_flash.tres")
const TELEPORT_FADE_MATERIAL: ShaderMaterial = preload("res://resources/Materials_Shaders/teleport_material_VERTICAL.tres")

@onready var muzzle:Node2D = $Muzzle
@onready var timer:Timer = $regen_timer
@onready var sprite:Sprite2D = $PlayerSprite
@onready var shield:Sprite2D = $playerShield
@onready var galaxy_particles:GPUParticles2D = $GalaxyParticles
@onready var galaxy_warp_sound:AudioStreamPlayer = %Galaxy_warp
@onready var animation:AnimationPlayer = $AnimationPlayer
@onready var camera:Camera2D = $Camera2D


@export var damage_indicator: PackedScene
@export var torpedo_scene: PackedScene

# Maneuverability variables
@export var base_max_speed: int = 750
var max_speed:int:
	get:
		return PlayerUpgrades.SpeedAdd + (base_max_speed * PlayerUpgrades.SpeedMult)

@export var base_rotation_speed: int = 150
var rotation_speed:int:
	get:
		return PlayerUpgrades.RotateAdd + (base_rotation_speed * PlayerUpgrades.RotateMult)

var base_acceleration:int= 5
var acceleration:int:
	get:
		return PlayerUpgrades.AccelAdd + (base_acceleration * PlayerUpgrades.AccelMult)


# Health variables
@export var base_max_HP: int = 150:
	set(value):
		base_max_HP = value
		SignalBus.playerMaxHealthChanged.emit(value)
var max_HP:int:
	get:
		return PlayerUpgrades.HullAdd + (base_max_HP * PlayerUpgrades.HullMult)
		
var hp_current:float = max_HP:
	set(value):
		hp_current = clamp(value, 0, max_HP)
		SignalBus.playerHealthChanged.emit(hp_current)

@export var shield_on:bool = true

# Energy system variables
@export var base_max_energy: int = 150
var max_energy:int:
	get:
		return PlayerUpgrades.MaxEnergyAdd + (base_max_energy * PlayerUpgrades.MaxEnergyMult)
		
var energy_current:float = max_energy:
	set(value):
		energy_current = clamp(value, 0, max_energy)
		SignalBus.playerEnergyChanged.emit(energy_current)
	

var base_rate_of_fire:float = 0.2
var shoot_rate_mult:float = 1.0
var rate_of_fire:float:
	get:
		return (PlayerUpgrades.FireRateAdd + (base_rate_of_fire * PlayerUpgrades.FireRateMult))
		
# Cargo upgrade variables
@export var base_cargo_size: int = 1:
	get:
		return Utility.SHIP_DATA.CARGO_SIZE + PlayerUpgrades.CargoAdd
var current_cargo:int = 0

@export var warp_range: int = 2
#@export var warp_range: int = 1:
	#get:
		#return PlayerUpgrades.AntimatterAdd + (enemy_data.max_antimatter * PlayerUpgrades.AntimatterMult)


func set_player_direction(joystick_direction) -> void:
	direction = joystick_direction


func _ready() -> void:
	Utility.mainScene.player = self
	Navigation.player_range = warp_range
	
	# Signal setup
	SignalBus.player_type_changed.connect(_sync_data_to_resource)
	SignalBus.player_type_changed.connect(_sync_stats_to_resource)
	SignalBus.missionAccepted.connect(mission_accept)
	SignalBus.finishMission.connect(mission_finish)
	SignalBus.joystickMoved.connect(set_player_direction)
	SignalBus.playerDied.connect(mission_finish)
	SignalBus.teleport_player.connect(teleport)
	SignalBus.triggerGalaxyWarp.connect(galaxy_warp_out)
	
	
	var spawn_options: Array = get_tree().get_nodes_in_group("player_spawn_area")
	self.global_position = spawn_options[0].global_position
	
	sprite.material.set("shader_parameter/flash_value", 0.0)
	
	_sync_data_to_resource(Utility.SHIP_TYPES.D5_Class)
	_sync_stats_to_resource(Utility.SHIP_TYPES.D5_Class)
	
	_set_ship_scale(Vector2(1.5, 1.5))

func _sync_data_to_resource(ship:Utility.SHIP_TYPES):
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[ship]
	
	sprite.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
	faction = ship_data.FACTION
	shield.scale = Vector2(float(ship_data.SHIELD_SCALE_X), float(ship_data.SHIELD_SCALE_Y)) * base_scale
	muzzle.position = Vector2(0, ship_data.MUZZLE_POS)
	muzzle.position.y = ship_data.MUZZLE_POS * base_scale.y
	faction = ship_data.FACTION
	
	var rawColl = ship_data.COLLISION_POLY
	var parsed_array = JSON.parse_string(rawColl)
	var PV2Array = PackedVector2Array()
	for pair in parsed_array:
		PV2Array.append(Vector2(pair[0], pair[1]))
	PV2Array = center_polygon(PV2Array)
	$hitbox_area/CollisionPolygon2D.polygon = PV2Array
	$WorldCollisionShape.polygon = PV2Array

func _sync_stats_to_resource(ship:Utility.SHIP_TYPES):
	var ship_stats:Dictionary = Utility.PLAYER_SHIP_STATS.values()[ship]
	
	base_max_speed = ship_stats.SPEED
	base_rotation_speed = ship_stats.ROTATION_SPEED
	base_max_HP = ship_stats.MAX_HP
	shield.base_max_SP = ship_stats.MAX_SHIELD
	shoot_rate_mult = ship_stats.SHOOT_MULTIPLIER
	base_cargo_size = ship_stats.CARGO_SIZE

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
		var shifted = centered + Vector2(0, 0)
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
	if !alive: return
	
	#print(global_position)
	
	if GameSettings.speedOverride == true:
		max_speed = GameSettings.maxSpeed
	else:
		max_speed = max_speed

	# Movement check for idle audio
	if abs(velocity.x)+abs(velocity.y)>100 and Utility.mainScene.in_galaxy_warp:
		idle_sound(true)
	else:
		idle_sound(false)
		
	if !$Laser.laserStatus and !energyTime:
		energy_current += energy_regen_speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		shooting_button_held = true
	if event.is_action_released("left_click"):
		shooting_button_held = false


func _physics_process(delta: float) -> void:
	if !alive or GameSettings.menuStatus == true: return
	
	if Input.is_action_just_pressed("warp"):
		if Utility.mainScene.in_galaxy_warp == false:
			warping_state_change("SMOOTH")

	if shooting_button_held:
		if !shoot_cd:
			if !warping_active:
				shoot_cd = true
				shoot_torpedo()
				await get_tree().create_timer(rate_of_fire).timeout
				shoot_cd = false
				
	_handle_movement(delta)

	move_and_slide()


func _handle_movement(delta: float) -> void:
	if Utility.mainScene.in_galaxy_warp == false:
	# Check for keyboard input (Windows) and add to direction
		if OS.get_name() == "Windows":
			direction.y = Input.get_axis("move_forward", "move_backward")  # Forward/backward movement

		# Add joystick direction for Android or hybrid control
		#direction += direction
		#print(direction)
		# Apply forward/backward thrust logic
		if direction.y != 0:
			velocity += Vector2(0, direction.y).rotated(rotation) * acceleration / warpm_v
			velocity = velocity.limit_length(max_speed/warpm_v)
		else:
			# Gradually slow down when no input
			velocity = velocity.move_toward(Vector2.ZERO, 3)
			
		if direction.x !=0:
			rotate(deg_to_rad(direction.x * rotation_speed * delta * warpm_v))
		
		# Handle rotation for keyboard input
		if OS.get_name() == "Windows":
			if Input.is_action_pressed("rotate_right"):
				rotate(deg_to_rad(rotation_speed * delta * warpm_r))
			if Input.is_action_pressed("rotate_left"):
				rotate(deg_to_rad(-rotation_speed * delta * warpm_r))


var current_tweens: Array = []
func warping_state_change(speed) -> void: # Reverses warping state
		# Stop any ongoing tweens
	for tween:Tween in current_tweens:
		if tween.is_running():
			tween.stop()

	current_tweens.clear()  # Clear the list of running tweens
	
	if warping_active: # Transition to impulse
		warpTimeout()
		warping_active = false
		match speed:
			"INSTANT":
				scale = base_scale
				warpm_v = 1.0
				warpm_r = 1.0
				shield.call_deferred("fadein_SMOOTH")
			"SMOOTH":
				var tween_scale: Object = create_tween() # Ship sprite scale
				tween_scale.tween_property(self, "scale", base_scale, trans_length)
				current_tweens.append(tween_scale)
				
				var tween_v: Object = create_tween() # Max Velocity
				tween_v.tween_property(self, "warpm_v", 1.0, trans_length*4)
				current_tweens.append(tween_v)
				
				var tween_r: Object = create_tween() # Rotation speed
				tween_r.tween_property(self, "warpm_r", 1.0, trans_length)
				current_tweens.append(tween_r)
				
				shield.fadein_SMOOTH()
				warp_sound_off()
	else: # Transition to warp
		warping_active = true
		warp_sound_on()
		match speed:
			"INSTANT":
				scale = base_scale * Vector2(1, 1.70)
				warpm_v = warp_multiplier
				warpm_r = warp_multiplier
				shield.fadeout_INSTANT()
			"SMOOTH":
				var tween_scale: Object = create_tween() # Ship sprite scale
				tween_scale.tween_property(self, "scale", base_scale * Vector2(1, 1.70), trans_length)
				current_tweens.append(tween_scale)
				
				var tween_v: Object = create_tween() # Max Velocity
				tween_v.tween_property(self, "warpm_v", warp_multiplier, trans_length)
				current_tweens.append(tween_v)
				
				var tween_r: Object = create_tween() # Rotation speed
				tween_r.tween_property(self, "warpm_r", warp_multiplier, trans_length)
				current_tweens.append(tween_r)
				
				shield.fadeout_SMOOTH()


func shoot_torpedo() -> void:
	var t: Area2D = torpedo_scene.instantiate()
	if energy_current > t.energy_cost and warpTime == false and Utility.mainScene.in_galaxy_warp == false:
		t.position = muzzle.global_position
		t.rotation = self.rotation
		t.z_index = -1
		
		t.set_collision_layer_value(9, true) # Sets layer to player projectile
		t.set_collision_mask_value(3, true) # Turns on enemy hitbox
		t.set_collision_mask_value(8, true) # Turns on enemy shield
		
		%HeavyTorpedo.pitch_scale = randf_range(0.95, 1.05)
		%HeavyTorpedo.play()
		$Projectiles.add_child(t)


func energy_drain(energy: float) -> void:
	energy_current -= energy


func killPlayer() -> void:
	if alive:
		Utility.mainScene.in_galaxy_warp = false
		%PlayerDieSound.play()
		alive = false
		self.visible = false
		shield.shieldActive = false
		
		if warping_active == true:
			warping_state_change("INSTANT")
		
		#Kill player stats
		hp_current = 0
		energy_current = 0
		shield.sp_current = 0
		shield.damageTime = true
		
		await get_tree().create_timer(1.5).timeout
		SignalBus.playerDied.emit()


func respawn(pos: Vector2) -> void:
	if alive == false:
		alive = true
		SignalBus.playerRespawned.emit()
		
		global_position = pos
		velocity = Vector2.ZERO
		self.visible = true
		
		# Restores all HUD values to max
		hp_current = max_HP #Resets HP to max
		energy_current = max_energy #Resets energy
		shield.sp_current = shield.base_max_SP #Resets Shield
	
		rotation = 0 #Sets rotation to north
		
		shield.shieldAlive()

		shield.damageTime = false


func energyTimeout() -> void: #Turns off energy regen for 1 second after firing laser
	energyTime = true
	if timer.is_stopped() == false: # If timer is already running, restarts timer fresh
		timer.stop()
		timer.start()
		await timer.timeout
		energyTime = false
	if timer.is_stopped() == true: # Starts timer if it is not already
		timer.start()
		await timer.timeout
		energyTime = false


func warpTimeout() -> void: #Turns off torpedo shooting for half of trans_length after leaving warp
	warpTime = true
	await get_tree().create_timer(trans_length/2).timeout
	warpTime = false


func teleport(xCoord: int, yCoord: int) -> void: # Uses coords from cheat menu to teleport player
	global_position = Vector2(xCoord, yCoord)
	velocity = Vector2(0, 0)
	if warping_active == true:
		warping_state_change("INSTANT")


#Audio functions
# Movement
func warp_sound_on() -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(%ship_idle, "volume_db", -60, 2.0) # Reduces idle sound volume
	%warp_on.play()


func warp_sound_off() -> void:
	%warp_off.play()


func idle_sound(active: bool) -> void:
	if warping_active == true:
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

#Weapons
func take_damage(damage:float, hit_pos: Vector2) -> void:
	if Utility.mainScene.in_galaxy_warp == false:
		hp_current -= damage # Take damage
		SignalBus.playerShieldChanged.emit(hp_current) # Update HUD
		Utility.createDamageIndicator(damage, Utility.damage_red, hit_pos)
		
		if hp_current <= 0:
			killPlayer()


func _teleport_shader_toggle(toggle: String) -> void:
	if toggle == "cloak":
		sprite.material = TELEPORT_FADE_MATERIAL
		var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite.material, "shader_parameter/progress", 1.0, 3.0)
	elif toggle == "uncloak":
		sprite.material = TELEPORT_FADE_MATERIAL
		var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite.material, "shader_parameter/progress", 0.0, 4.0)


func velocity_check() -> bool:
	# Check base warp criteria
	var base_check = (
		!Utility.mainScene.in_galaxy_warp and
		velocity.x > -100 and velocity.x < 100 and
		velocity.y > -100 and velocity.y < 100 and
		!warping_active
	)
	
	if not base_check:
		return false
	else: return true


func galaxy_warp_out() -> void:
	SignalBus.entering_galaxy_warp.emit()
	Utility.mainScene.in_galaxy_warp = true
	
	self.velocity = Vector2.ZERO
	
	Navigation.entry_coords = Navigation.get_entry_point(self.global_rotation)
	
	galaxy_warp_sound.play()
	await get_tree().create_timer(1.5).timeout
	shield.fadeout_SMOOTH()
	
	await get_tree().create_timer(0.5).timeout # 2 sec
	
	# Velocity tween
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "velocity", Vector2(0, -2500).rotated(rotation), 8.0)
	
	
	await get_tree().create_timer(1.0).timeout #3.0 sec
	create_tween().tween_property(galaxy_particles, "amount_ratio", 1.0, 8.0)
	galaxy_particles.emitting = true
	
	#Camera Zoom out
	create_tween().tween_property(camera, "zoom", Vector2(0.4, 0.4), trans_length/warp_multiplier*3)
	
	await get_tree().create_timer(3.0).timeout #6.0 sec
	#print("flat, scale")
	create_tween().tween_property(galaxy_particles.process_material, "flatness", 0.0, 5.0)
	create_tween().tween_property(galaxy_particles.process_material, "scale_min", 1.0, 3.5)
	create_tween().tween_property(galaxy_particles.process_material, "scale_max", 2.0, 3.5)
	
	await get_tree().create_timer(2.5).timeout #7.5 sec
	var tween2: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween2.tween_property(galaxy_warp_sound, "pitch_scale", 2.5, 3.5)
	
	await get_tree().create_timer(2.5).timeout
	_teleport_shader_toggle("cloak")
	
	await get_tree().create_timer(1.0).timeout #11 sec, velocity tween ends
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


func mission_accept(mission_data:Dictionary) -> void:
	current_mission = mission_data
	has_mission = true
	current_cargo += 1


func mission_finish() -> void:
	current_mission.clear()
	has_mission = false
	current_cargo -= 1


func create_damage_indicator(damage:float, shooter:String, projectile:Area2D) -> void:
	var spawn: Marker2D = projectile.create_damage_indicator(damage, $hitbox_area.name)
	projectile.kill_projectile($hitbox_area.name)
	$Hitmarkers.add_child(spawn)


func _on_laser_ended() -> void:
	create_damage_indicator
