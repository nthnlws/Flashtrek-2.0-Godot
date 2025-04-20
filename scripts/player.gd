class_name Player extends CharacterBody2D

@onready var intersection_line: Line2D = $intersection_line

signal died

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

var player_name: String = "USS Enterprise"
var animation_scale:Vector2 = Vector2(1, 1)

const WHITE_FLASH_MATERIAL = preload("res://resources/Materials_Shaders/white_flash.tres")
const TELEPORT_FADE_MATERIAL = preload("res://resources/Materials_Shaders/teleport_material.tres")

@onready var muzzle = $Muzzle
@onready var timer:Timer = $regen_timer
@onready var sprite:Sprite2D = $PlayerSprite
@onready var shield:Sprite2D = $playerShield
@onready var particles:GPUParticles2D = $WarpParticles
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
	

@onready var base_weapon_drain:float = torpedo_scene.instantiate().energy_drain
var weapon_drain:float:
	get:
		return PlayerUpgrades.EnergyDrainAdd + (base_weapon_drain * PlayerUpgrades.EnergyDrainMult)

var base_rate_of_fire:float = 0.2
var rate_of_fire:float:
	get:
		return PlayerUpgrades.FireRateAdd + (base_rate_of_fire * PlayerUpgrades.FireRateMult)
		
# Cargo upgrade variables
@export var base_cargo_size: int = 1:
	get:
		return enemy_data.max_cargo_size + PlayerUpgrades.CargoAdd
var current_cargo:int = 0

@export var ship_antimatter: int = 100:
	get:
		return PlayerUpgrades.AntimatterAdd + (enemy_data.max_antimatter * PlayerUpgrades.AntimatterMult)
var current_antimatter:int = 0


func set_player_direction(joystick_direction):
	direction = joystick_direction
	
	
func _ready():
	Utility.mainScene.player = self
	# Signal setup
	SignalBus.enemy_type_changed.connect(change_enemy_resource)
	SignalBus.joystickMoved.connect(set_player_direction)
	#SignalBus.Quad1_clicked.connect(galaxy_travel)
	SignalBus.teleport_player.connect(teleport)
	SignalBus.triggerGalaxyWarp.connect(galaxy_travel)
	
	
	var spawn_options: Array = get_tree().get_nodes_in_group("player_spawn_area")
	self.global_position = spawn_options[0].global_position
	#self.global_rotation = deg_to_rad(randi_range(-20, 20))
	
	#animation_scale = animation.scale
	sprite.material.set("shader_parameter/flash_value", 0.0)
	
	current_antimatter = ship_antimatter
	
	#%PlayerSprite.texture.region = Utility.ship_sprites["La Sirena"]
	sync_to_resource()
	
	
func _process(delta):
	if !alive: return
	
	if GameSettings.speedOverride == true:
		max_speed = GameSettings.maxSpeed
	else:
		max_speed = max_speed

	# Movement check for idle audio
	if abs(velocity.x)+abs(velocity.y)>100 and Utility.mainScene.in_galaxy_warp:
		idle_sound(true)
	else:
		idle_sound(false)
		
	#Laser energy drain system
	if $Laser.laserClickState == true:
		if GameSettings.unlimitedEnergy == false:
			energy_current -= %Laser.energy_drain * delta
		energyTimeout()
	
	if $Laser.laserClickState == false and energy_current < max_energy and energyTime == false:
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

func _handle_movement(delta):
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

func change_enemy_resource(ENEMY_TYPE):
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
				tween_v.tween_property(self, "warpm_v", 1.0, trans_length*5)
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
	if energy_current > weapon_drain and warpTime == false and Utility.mainScene.in_galaxy_warp == false:
		
		var t: Area2D = torpedo_scene.instantiate()
		t.position = muzzle.global_position
		t.rotation = self.rotation
		t.shooter = "player"
		%HeavyTorpedo.pitch_scale = randf_range(0.95, 1.05)
		%HeavyTorpedo.play()
		$Projectiles.add_child(t)
		if GameSettings.unlimitedEnergy == false:
			energy_current -= weapon_drain


func kill_player():
	if alive:
		%PlayerDieSound.play()
		alive = false
		self.visible = false
		shield.shieldActive = false
		
		var spawn_options = get_tree().get_nodes_in_group("player_spawn_area") #TODO Update spawn options array in LevelManager
		global_position = spawn_options[0].global_position
		
		if warping_active == true:
			warping_state_change("INSTANT")
		await get_tree().create_timer(1.0).timeout
		
		#Kill player stats
		hp_current = 0
		energy_current = 0
		shield.sp_current = 0
		shield.damageTime = true
		respawn(spawn_options[0].global_position)

func respawn(pos):
	if alive == false:
		alive = true
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

# Take torpedo damage
func _on_hitbox_area_entered(area):
	if area.is_in_group("projectile") and area.shooter != "player":
		area.kill_projectile("hull")
		%TorpedoHit.play()
		
		# Create damage indicator
		var damage_taken = area.damage
		
		
		if GameSettings.unlimitedHealth == false:
			create_damage_indicator(damage_taken, area.global_position, Utility.damage_red)
			hp_current -= damage_taken
		else: create_damage_indicator(0, area.global_position, Utility.damage_red)
		
		if hp_current <= 0 and alive:
			kill_player()
	elif area.is_in_group("enemy"):
		pass

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
	
func teleport(xCoord, yCoord): # Uses coords from cheat menu to teleport player
	global_position = Vector2(xCoord, yCoord)
	velocity = Vector2(0, 0)
	if warping_active == true:
		warping_state_change("INSTANT")
	

#Audio functions
# Movement
func warp_sound_on():
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(%ship_idle, "volume_db", -60, 2.0) # Reduces idle sound volume
	%warp_on.play() 

func warp_sound_off():
	%warp_off.play()

func idle_sound(active):
	if warping_active == true:
		#$ship_idle.stop()
		pass
	elif %ship_idle.playing == false:
		%ship_idle.play()
	elif %ship_idle.playing == true:
		if active == false:
				var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
				tween.tween_property(%ship_idle, "volume_db", -25, 2.0)
		elif active == true:
				var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
				tween.tween_property(%ship_idle, "volume_db", -15, 2.0)

#Weapons
#TODO: Weapon sounds here

func create_damage_indicator(damage_taken:float, hit_pos:Vector2, color:String):
	var damage = damage_indicator.instantiate()
	damage.find_child("Label").text = color + str(damage_taken)
	damage.global_position = hit_pos
	get_parent().add_child(damage)

func _teleport_shader_toggle():
	sprite.material = TELEPORT_FADE_MATERIAL
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite.material, "shader_parameter/progress", 1.0, 3.0)
	
	
func galaxy_travel():
	if !Utility.mainScene.galaxy_warp_check():
		var error_message: String = "Must be stationary and in impulse to warp"
		SignalBus.changePopMessage.emit(error_message)
		
	if Utility.mainScene.galaxy_warp_check():
		var entry_coords = Navigation.get_square_line_intersection(global_position, global_rotation)
		
		SignalBus.entering_galaxy_warp.emit()
		galaxy_warp_sound.play()
		await get_tree().create_timer(1.5).timeout
		shield.fadeout_SMOOTH()
		
		await get_tree().create_timer(0.5).timeout # 2 sec
		var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "velocity", Vector2(0, -2500).rotated(rotation), 8.0)
		
		
		await get_tree().create_timer(1.0).timeout #2.5 sec
		create_tween().tween_property(particles, "amount_ratio", 1.0, 8.0)
		particles.emitting = true
		
		#Camera Zoom out
		create_tween().tween_property(camera, "zoom", Vector2(0.4, 0.4), trans_length/warp_multiplier*3)
		
		await get_tree().create_timer(3.0).timeout #5.5 sec
		#print("flat, scale")
		create_tween().tween_property(particles.process_material, "flatness", 0.0, 5.0)
		create_tween().tween_property(particles.process_material, "scale_min", 1.0, 3.5)
		create_tween().tween_property(particles.process_material, "scale_max", 2.0, 3.5)
		
		await get_tree().create_timer(2.5).timeout #8 sec
		#TODO Check player speed, velocity is not 100% at time of warp or in impulse
		var tween2 = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween2.tween_property(galaxy_warp_sound, "pitch_scale", 2.5, 3.5)
		print("full warp")
		
		
		await get_tree().create_timer(3.5).timeout #10 sec, velocity tween ends
		create_tween().tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.8)
		create_tween().tween_property(particles, "amount_ratio", 0.0, 2.5)
		
		_teleport_shader_toggle()
		
		await get_tree().create_timer(0.30).timeout
		%warp_boom.play()
		
		await get_tree().create_timer(0.20).timeout
		galaxy_warp_sound.stop()
		
		#sprite.material.set("shader_parameter/flash_value", 1.0)
		$warp_anim.visible = true
		$warp_anim.play("warp_collapse")
		
		# Camera zoom in
		var tween3 = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
		tween3.tween_property(camera, "zoom", Vector2(2.75, 2.75), 3.0)
		
		
		SignalBus.galaxy_warp_screen_fade.emit()
		
		#self.global_position = entry_coords["entry_pos"]
		#self.global_rotation = entry_coords["entry_rotation"]
