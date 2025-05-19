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
var direction:Vector2 = Vector2(0, 0)
var warp_multiplier:float = 0.45
var warpm_r:float = 1.0
var warpm_v:float = 1.0

var has_mission: bool = false
var current_mission: Dictionary = {}
var player_name: String = "USS Enterprise"
var animation_scale:Vector2 = Vector2(1, 1)

const WHITE_FLASH_MATERIAL = preload("res://resources/Materials_Shaders/white_flash.tres")
const TELEPORT_FADE_MATERIAL = preload("res://resources/Materials_Shaders/teleport_material_VERTICAL.tres")

@onready var muzzle = $Muzzle
@onready var timer:Timer = $regen_timer
@onready var sprite:Sprite2D = $PlayerSprite
@onready var shield:Sprite2D = $playerShield
@onready var galaxy_particles:GPUParticles2D = $GalaxyParticles
@onready var galaxy_warp_sound = %Galaxy_warp
@onready var animation = $AnimationPlayer
@onready var camera = $Camera2D

#TEMPORARY RESOURCE LINKS
@export var BIRD_OF_PREY_ENEMY: Resource
@export var JEM_HADAR_ENEMY: Resource
@export var ENTERPRISE_TNG_ENEMY: Resource
@export var MONAVEEN_ENEMY: Resource
@export var CALIFORNIA_ENEMY: Resource
@export var KAPLAN_ENEMY: Resource

@export var SHIP_SPRITES = preload("res://assets/textures/ships/ship_sprites.png")
@export var enemy_data: Enemy # Default resource file for stats and sprite
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
@export var base_max_HP: int = 150
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
	

#@onready var base_weapon_drain:float = torpedo_scene.instantiate().energy_drain
#var weapon_drain:float:
	#get:
		#return PlayerUpgrades.EnergyDrainAdd + (base_weapon_drain * PlayerUpgrades.EnergyDrainMult)

var base_rate_of_fire:float = 0.2
var rate_of_fire:float:
	get:
		return PlayerUpgrades.FireRateAdd + (base_rate_of_fire * PlayerUpgrades.FireRateMult)
		
# Cargo upgrade variables
@export var base_cargo_size: int = 1:
	get:
		return enemy_data.max_cargo_size + PlayerUpgrades.CargoAdd
var current_cargo:int = 0

@export var warp_range: int = 2
#@export var warp_range: int = 1:
	#get:
		#return PlayerUpgrades.AntimatterAdd + (enemy_data.max_antimatter * PlayerUpgrades.AntimatterMult)


func set_player_direction(joystick_direction):
	direction = joystick_direction
	
	
func _ready():
	Utility.mainScene.player = self
	Navigation.player_range = warp_range
	# Signal setup
	SignalBus.missionAccepted.connect(mission_accept)
	SignalBus.finishMission.connect(mission_finish)
	SignalBus.enemy_type_changed.connect(change_enemy_resource)
	SignalBus.joystickMoved.connect(set_player_direction)
	SignalBus.playerDied.connect(mission_finish)
	SignalBus.teleport_player.connect(teleport)
	SignalBus.triggerGalaxyWarp.connect(galaxy_warp_out)
	
	
	var spawn_options: Array = get_tree().get_nodes_in_group("player_spawn_area")
	self.global_position = spawn_options[0].global_position
	#self.global_rotation = deg_to_rad(randi_range(-20, 20))
	
	#animation_scale = animation.scale
	sprite.material.set("shader_parameter/flash_value", 0.0)
	
	#%PlayerSprite.texture.region = Utility.ship_sprites["La Sirena"]
	sync_to_resource()
	
	
func _process(delta):
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


func _unhandled_input(event):
	if event.is_action_pressed("left_click"):
		shooting_button_held = true
	if event.is_action_released("left_click"):
		shooting_button_held = false
		
func _physics_process(delta):
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

func _handle_movement(delta: float):
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

func change_enemy_resource(ENEMY_TYPE: Utility.SHIP_NAMES):
	#TODO Link to RSS File
	match ENEMY_TYPE:
		Utility.SHIP_NAMES.Brel_Class:
			enemy_data = BIRD_OF_PREY_ENEMY
		Utility.SHIP_NAMES.JemHadar:
			enemy_data = JEM_HADAR_ENEMY
		Utility.SHIP_NAMES.Galaxy_Class:
			enemy_data = ENTERPRISE_TNG_ENEMY
		Utility.SHIP_NAMES.Monaveen:
			enemy_data = MONAVEEN_ENEMY
		Utility.SHIP_NAMES.California_Class:
			enemy_data = CALIFORNIA_ENEMY
		Utility.SHIP_NAMES.La_Sirena:
			enemy_data = KAPLAN_ENEMY
		_:
			enemy_data = BIRD_OF_PREY_ENEMY
			print("Default RSS file used")
	sync_to_resource()
	
	
func sync_to_resource():
	#TODO Have player variables automatically "Get:" from RSS file
	# Assign values from the resource
	base_max_speed = enemy_data.default_speed * 10 #Speed
	base_rotation_speed = enemy_data.rotation_rate * 50
	shield_on = enemy_data.shield_on
	
	shield.base_max_SP = enemy_data.max_shield_health # Health
	base_max_HP = enemy_data.max_hp
	hp_current = enemy_data.max_hp
	
	base_rate_of_fire = enemy_data.rate_of_fire / 5 # Weapons
	muzzle.position = enemy_data.muzzle_pos

	sprite.texture.region = Utility.ship_sprites.values()[enemy_data.enemy_type]
	#sprite.scale = enemy_data.sprite_scale
	#shield.scale = enemy_data.ship_shield_scale * enemy_data.sprite_scale
	#animation.scale = enemy_data.sprite_scale * animation_scale * Vector2(2, 2)


	# Load the collision shape from the resource
	#if enemy_data.collision_shape and enemy_data.collision_shape is ConvexPolygonShape2D:
		#$Hitbox/CollisionShape2D2.shape = enemy_data.collision_shape
		#$WorldCollisionShape.shape = enemy_data.collision_shape
		#$Hitbox/CollisionShape2D2.scale = enemy_data.sprite_scale
		#$WorldCollisionShape.scale = enemy_data.sprite_scale
	#else:
		#print("Warning: No collision shape found for ", enemy_data.enemy_name)

	# Initialize shield settings
	#shield.enemy_name = enemy_data.enemy_name
		

var current_tweens = []
func warping_state_change(speed): # Reverses warping state
		# Stop any ongoing tweens
	for tween in current_tweens:
		if tween.is_running():
			tween.stop()

	current_tweens.clear()  # Clear the list of running tweens
	
	if warping_active: # Transition to impulse
		warpTimeout()
		warping_active = false
		match speed:
			"INSTANT":
				scale = Vector2(1, 1)
				warpm_v = 1.0
				warpm_r = 1.0
				shield.call_deferred("fadein_SMOOTH")
			"SMOOTH":
				var tween_scale = create_tween() # Ship sprite scale
				tween_scale.tween_property(self, "scale", Vector2(1, 1), trans_length)
				current_tweens.append(tween_scale)
				
				var tween_v = create_tween() # Max Velocity
				tween_v.tween_property(self, "warpm_v", 1.0, trans_length*4)
				current_tweens.append(tween_v)
				
				var tween_r = create_tween() # Rotation speed
				tween_r.tween_property(self, "warpm_r", 1.0, trans_length)
				current_tweens.append(tween_r)
				
				shield.fadein_SMOOTH()
				warp_sound_off()
	else: # Transition to warp
		warping_active = true
		warp_sound_on()
		match speed:
			"INSTANT":
				scale = Vector2(1, 1.70)
				warpm_v = warp_multiplier
				warpm_r = warp_multiplier
				shield.fadeout_INSTANT()
			"SMOOTH":
				var tween_scale = create_tween() # Ship sprite scale
				tween_scale.tween_property(self, "scale", Vector2(1, 1.70), trans_length)
				current_tweens.append(tween_scale)
				
				var tween_v = create_tween() # Max Velocity
				tween_v.tween_property(self, "warpm_v", warp_multiplier, trans_length)
				current_tweens.append(tween_v)
				
				var tween_r = create_tween() # Rotation speed
				tween_r.tween_property(self, "warpm_r", warp_multiplier, trans_length)
				current_tweens.append(tween_r)
				
				shield.fadeout_SMOOTH()


func shoot_torpedo():
	var t: Area2D = torpedo_scene.instantiate()
	if energy_current > t.energy_cost and warpTime == false and Utility.mainScene.in_galaxy_warp == false:
		t.position = muzzle.global_position
		t.rotation = self.rotation
		
		t.set_collision_layer_value(9, true) # Sets layer to player projectile
		t.set_collision_mask_value(3, true) # Turns on enemy hitbox
		t.set_collision_mask_value(8, true) # Turns on enemy shield
		
		%HeavyTorpedo.pitch_scale = randf_range(0.95, 1.05)
		%HeavyTorpedo.play()
		$Projectiles.add_child(t)

func energy_drain(energy):
	energy_current -= energy
	
	
func killPlayer():
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

func respawn(pos: Vector2):
	if alive == false:
		alive = true
		SignalBus.playerRespawned.emit()
		
		global_position = pos
		velocity = Vector2.ZERO
		self.visible = true
		
		# Restores all HUD values to max
		hp_current = max_HP #Resets HP to max
		energy_current = max_energy #Resets energy
		shield.sp_current = shield.max_SP #Resets Shield
	
		rotation = 0 #Sets rotation to north
		
		shield.shieldAlive()

		shield.damageTime = false


func energyTimeout(): #Turns off energy regen for 1 second after firing laser
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
	
func warpTimeout(): #Turns off torpedo shooting for half of trans_length after leaving warp
	warpTime = true
	await get_tree().create_timer(trans_length/2).timeout
	warpTime = false
	
func teleport(xCoord: int, yCoord: int): # Uses coords from cheat menu to teleport player
	global_position = Vector2(xCoord, yCoord)
	velocity = Vector2(0, 0)
	if warping_active == true:
		warping_state_change("INSTANT")
	

#Audio functions
# Movement
func warp_sound_on():
	var tween: Object = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(%ship_idle, "volume_db", -60, 2.0) # Reduces idle sound volume
	%warp_on.play() 

func warp_sound_off():
	%warp_off.play()

func idle_sound(active: bool):
	if warping_active == true:
		#$ship_idle.stop()
		pass
	elif %ship_idle.playing == false:
		%ship_idle.play()
	elif %ship_idle.playing == true:
		if active == false:
				var tween: Object = create_tween().set_trans(Tween.TRANS_LINEAR)
				tween.tween_property(%ship_idle, "volume_db", -25, 2.0)
		elif active == true:
				var tween: Object = create_tween().set_trans(Tween.TRANS_LINEAR)
				tween.tween_property(%ship_idle, "volume_db", -15, 2.0)

#Weapons
func take_damage(damage:float, hit_pos: Vector2):
	if Utility.mainScene.in_galaxy_warp == false:
		hp_current -= damage # Take damage
		SignalBus.playerShieldChanged.emit(hp_current) # Update HUD
		Utility.createDamageIndicator(damage, Utility.damage_red, hit_pos)
		
		if hp_current <= 0:
			killPlayer()

func _teleport_shader_toggle(toggle: String):
	if toggle == "cloak":
		sprite.material = TELEPORT_FADE_MATERIAL
		var tween: Object = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite.material, "shader_parameter/progress", 1.0, 3.0)
	elif toggle == "uncloak":
		sprite.material = TELEPORT_FADE_MATERIAL
		var tween: Object = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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
	
func galaxy_warp_out():
	SignalBus.entering_galaxy_warp.emit()
	Utility.mainScene.in_galaxy_warp = true
	
	self.velocity = Vector2.ZERO
	
	Navigation.entry_coords = Navigation.get_entry_point(self.global_rotation)
	
	galaxy_warp_sound.play()
	await get_tree().create_timer(1.5).timeout
	shield.fadeout_SMOOTH()
	
	await get_tree().create_timer(0.5).timeout # 2 sec
	
	# Velocity tween
	var tween: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
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

func mission_accept(mission_data):
	current_mission = mission_data
	has_mission = true
	current_cargo += 1

func mission_finish():
	current_mission.clear()
	has_mission = false
	current_cargo -= 1

func create_damage_indicator(damage:float, shooter:String, projectile:Area2D):
	var spawn: Marker2D = projectile.create_damage_indicator(damage, $hitbox_area.name)
	projectile.kill_projectile($hitbox_area.name)
	$Hitmarkers.add_child(spawn)


func _on_laser_ended() -> void:
	create_damage_indicator
