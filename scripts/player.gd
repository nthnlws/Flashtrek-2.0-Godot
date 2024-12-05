class_name Player extends CharacterBody2D

signal torpedo_shot(torpedo)
signal died

var shooting_button_held:bool = false # Variable to check if fire button is currently clicked

var acceleration:int= 5

@export var damage_indicator: PackedScene
@export var torpedo_scene: PackedScene


@export var base_max_speed: int = 500
var max_speed:int:
	get:
		return PlayerUpgrades.SpeedAdd + (base_max_speed * PlayerUpgrades.SpeedMult)

@export var base_rotation_speed: int = 150
var rotation_speed:int:
	get:
		return PlayerUpgrades.RotateAdd + (base_rotation_speed * PlayerUpgrades.RotateMult)

@export var base_max_HP: int = 150
var max_HP:int:
	get:
		return PlayerUpgrades.HullAdd + (base_max_HP * PlayerUpgrades.HullMult)


var trans_length:float = 0.8
var direction:Vector2 = Vector2(0, 0)
var warp_multiplier:float = 0.4
var warpm:float = 1.0

var player_name = "USS Enterprise"

#Health variables
var hp_current:float = max_HP:
	set(value):
		hp_current = clamp(value, 0, max_HP)
		SignalBus.playerHealthChanged.emit(hp_current)

#@export var shield_on:bool = true

#Energy system variables
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

var warping_active:bool = false
var shield_active:bool = false
var energyTime:bool = false
var warpTime:bool = false
var energy_regen_speed:int = 10

@onready var shield = $playerShield

var shoot_cd:bool = false
var rate_of_fire:float = 0.2

var alive: bool = true

func set_player_direction(joystick_direction):
	direction = joystick_direction
	
func _ready():
	# Signals
	SignalBus.joystickMoved.connect(set_player_direction)
	SignalBus.Quad1_clicked.connect(warping_state_change.bind("SMOOTH"))
	SignalBus.teleport_player.connect(teleport)
	
	Utility.mainScene.player.append(self)
	
	var spawn_options = get_tree().get_nodes_in_group("player_spawn_area")
	self.global_position = spawn_options[0].global_position


	#Upgrade applications
	rotation_speed = rotation_speed + PlayerUpgrades.RotateAdd + (rotation_speed * PlayerUpgrades.RotateMult)
	max_speed = max_speed + PlayerUpgrades.SpeedAdd + (max_speed * PlayerUpgrades.SpeedMult)
	
	
	SignalBus.player = self
	#%PlayerSprite.texture.region = Utility.ship_sprites["La Sirena"]

func _process(delta):
	if !alive: return
	
	if GameSettings.speedOverride == true:
		max_speed = GameSettings.maxSpeed
	else:
		max_speed = max_speed

	# Movement check for idle audio
	if abs(velocity.x)+abs(velocity.y)>100:
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
		warping_state_change("SMOOTH")

	if shooting_button_held:
		if !shoot_cd:
			if !warping_active:
				shoot_cd = true
				shoot_torpedo()
				await get_tree().create_timer(rate_of_fire).timeout
				shoot_cd = false
				
	handle_movement(delta)

	move_and_slide()

func handle_movement(delta):
	# Check for keyboard input (Windows) and add to direction
	if OS.get_name() == "Windows":
		direction.y = Input.get_axis("move_forward", "move_backward")  # Forward/backward movement

	# Add joystick direction for Android or hybrid control
	#direction += direction
	#print(direction)
	# Apply forward/backward thrust logic
	if direction.y != 0:
		velocity += Vector2(0, direction.y).rotated(rotation) * acceleration / warpm
		velocity = velocity.limit_length(max_speed/warpm)
	else:
		# Gradually slow down when no input
		velocity = velocity.move_toward(Vector2.ZERO, 3)
	
	if direction.x !=0:
		rotate(deg_to_rad(direction.x * rotation_speed * delta * warpm))
	
	# Handle rotation for keyboard input
	if OS.get_name() == "Windows":
		if Input.is_action_pressed("rotate_right"):
			rotate(deg_to_rad(rotation_speed * delta * warpm))
		if Input.is_action_pressed("rotate_left"):
			rotate(deg_to_rad(-rotation_speed * delta * warpm))

	
	
func warping_state_change(speed): # Reverses warping state
	if warping_active: # Transition to impulse
		warpTimeout()
		warping_active = false
		match speed:
			"INSTANT":
				scale = Vector2(1, 1)
				warpm = 1.0
				shield.call_deferred("fadein", "INSTANT")
			"SMOOTH":
				create_tween().tween_property(self, "scale", Vector2(1, 1), trans_length)
				create_tween().tween_property(self, "warpm", 1.0, trans_length)
				shield.fadein("SMOOTH")
				warp_sound_off()
	else: # Transition to warp
		warping_active = true
		warp_sound_on()
		match speed:
			"INSTANT":
				scale = Vector2(1, 1.70)
				warpm = warp_multiplier
				shield.fadeout("INSTANT")
			"SMOOTH":
				create_tween().tween_property(self, "scale", Vector2(1, 1.70), trans_length)
				create_tween().tween_property(self, "warpm", warp_multiplier, trans_length)
				shield.fadeout("SMOOTH")

	
func shoot_torpedo():
	if energy_current > weapon_drain && warpTime == false:
		
		var t = torpedo_scene.instantiate()
		t.position = $Muzzle.global_position
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
	if $Timer.is_stopped() == false: # If timer is already running, restarts timer fresh
		$Timer.stop()
		$Timer.start()
		await $Timer.timeout
		energyTime = false
	if $Timer.is_stopped() == true: # Starts timer if it is not already
		$Timer.start()
		await $Timer.timeout
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
