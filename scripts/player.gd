class_name Player extends CharacterBody2D

signal torpedo_shot(torpedo)
signal died

var shooting_button_held:bool = false # Variable to check if fire button is currently clicked

var acceleration:int= 5
@export var default_max_speed:int = 500
var max_speed:int = default_max_speed
var rotation_speed:int = 150
var trans_length:float = 0.8

var warp_multiplier:float = 0.4
var warpm:float = 1.0

#Health variables
const HP_MAX:int = 100
var hp_current:float = HP_MAX:
	set(value):
		hp_current = clamp(value, 0, HP_MAX)
		SignalBus.playerHealthChanged.emit(hp_current)

#@export var shield_on:bool = true

#Energy system variables
const ENERGY_MAX:int = 100
var energy_current:float = ENERGY_MAX:
	set(value):
		energy_current = clamp(value, 0, ENERGY_MAX)
		SignalBus.playerEnergyChanged.emit(energy_current)
	
@export var laser_drain_rate:float = 7.5
@export var torpedo_drain:int = 10

var warping_active:bool = false
var shield_active:bool = false
var energyTime:bool = false
var warpTime:bool = false
var energy_regen_speed:int = 10

var shield
var torpedo_scene = preload("res://scenes/torpedo.tscn")

var shoot_cd:bool = false
var rate_of_fire:float = 0.2

var alive: bool = true

func _ready():
	# Signals
	SignalBus.Quad1_clicked.connect(warping_state_change.bind("SMOOTH"))
	SignalBus.teleport_player.connect(teleport)
	
	Utility.mainScene.player.append(self)
	
	var spawn_options = get_tree().get_nodes_in_group("player_spawn_area")
	self.global_position = spawn_options[0].global_position
		
	GameSettings.maxSpeed = default_max_speed
	SignalBus.player = self
	shield = $playerShield

func _process(delta):
	if !alive: return
	
	if GameSettings.speedOverride == true:
		max_speed = GameSettings.maxSpeed
	else:
		max_speed = default_max_speed

	# Movement check for idle audio
	if abs(velocity.x)+abs(velocity.y)>100:
		idle_sound(true)
	else:
		idle_sound(false)
		
	#Laser energy drain system
	if $Laser.laserClickState == true:
		if GameSettings.unlimitedEnergy == false:
			energy_current -= laser_drain_rate * delta
		energyTimeout()
	
	if $Laser.laserClickState == false and energy_current < ENERGY_MAX and energyTime == false:
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
				
	var input_vector := Vector2(0, Input.get_axis("move_forward", "move_backward"))
	
	velocity += input_vector.rotated(rotation) * acceleration / warpm
	velocity = velocity.limit_length(max_speed/warpm)
	
	if Input.is_action_pressed("rotate_right"):
		rotate(deg_to_rad(rotation_speed*delta*warpm))
	if Input.is_action_pressed("rotate_left"):
		rotate(deg_to_rad(-rotation_speed*delta*warpm))
	
	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector2.ZERO, 3)
		
		
	#if OS.get_name() == "Android":
		#var direction = GameSettings.playerDirection
#
		#if direction:
			#velocity = direction * acceleration / warpm
		#else:
			#velocity = Vector2(0,0)
	
	move_and_slide()


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
	if energy_current > torpedo_drain && warpTime == false:
		
		var t = torpedo_scene.instantiate()
		t.position = self.position + Vector2(0, -25).rotated(self.rotation)
		t.rotation = self.rotation
		t.shooter = "player"
		%HeavyTorpedo.play()
		$Projectiles.add_child(t)
		if GameSettings.unlimitedEnergy == false:
			energy_current -= torpedo_drain


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
		hp_current = HP_MAX #Resets HP
		energy_current = ENERGY_MAX #Resets energy
		shield.sp_current = shield.SP_MAX #Resets Shield
	
		rotation = 0 #Sets rotation to north
		
		shield.shieldActive = true
		shield.shieldAlive()

		shield.damageTime = false

# Take torpedo damage
func _on_hitbox_area_entered(area):
	if area.is_in_group("projectile") and area.shooter != "player":
		area.queue_free()
		%TorpedoHit.play()
		if GameSettings.unlimitedHealth == false:
			var damage_taken = area.damage
			hp_current -= damage_taken
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
