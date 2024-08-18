class_name Player extends CharacterBody2D

signal torpedo_shot(torpedo)
signal died
signal warping
signal impulse

signal playerHealthChanged
signal playerEnergyChanged

var acceleration:int= 5
@export var default_max_speed:int = 400
var max_speed:int = default_max_speed
var rotation_speed:int = 150
var trans_length:float = 0.8

var warp_multiplier:float = 0.4
var warpm:float = 1.0

#Health variables
var hp_max:int = 100
var hp_current:int = hp_max
@export var shield_on:bool = true

#Energy system variables
var energy_max:int = 100
var energy_current:float = energy_max
@export var laser_drain_rate:float = 7.5
@export var torpedo_drain:int = 10

@onready var muzzle = $Muzzle
var warping_active:bool = false
var shield_active:bool = false
var energyTime:bool = false
var warpTime:bool = false
@export var energy_regen_speed:int = 10

var torpedo_scene = preload("res://scenes/torpedo.tscn")
var laser_scene = preload("res://scenes/laser.tscn")

var shoot_cd:bool = false
var rate_of_fire:float = 0.2

var alive: bool = true

func _ready():
	GameSettings.maxSpeed = default_max_speed
	Global.player = self
	if shield_on == true:
		GameSettings.playerShield = true
		var shieldScene = preload("res://scenes/playerShield.tscn")
		var newShield = shieldScene.instantiate()
		add_child(newShield)

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
			playerEnergyChanged.emit(energy_current)
		energyTimeout()
	if energy_current < 0:
		energy_current = 0
		playerEnergyChanged.emit(energy_current)
		energyTimeout()
	if energy_current > energy_max:
		energy_current = energy_max
		playerEnergyChanged.emit(energy_current)
	
	if $Laser.laserClickState == false and energy_current < energy_max and energyTime == false:
		energy_current += energy_regen_speed * delta
		playerEnergyChanged.emit(energy_current)


func _physics_process(delta):
	if !alive: return
	if GameSettings.menuStatus == true: return
	
	if Input.is_action_just_pressed("warp"):
		warping_state_change()

	if Input.is_action_pressed("shoot_torpedo"):
		if warping_active == false:
			if !shoot_cd:
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
	
	move_and_slide()

func warping_state_change(): #Reverses warping state
	var warpm:float = 1.0
	if warping_active == true: #Transition to impulse
		warpTimeout()
		warping_active = false
		create_tween().tween_property(self, "scale", Vector2(1, 1), trans_length)
		create_tween().tween_property(self, "warpm", 1.0, trans_length)
		get_node("playerShield").fadein()
		warping.emit()
		warp_sound_off()
		
	elif warping_active == false: #Transition to warp
		warping_active = true
		create_tween().tween_property(self, "scale", Vector2(1, 1.70), trans_length)
		create_tween().tween_property(self, "warpm", warp_multiplier, trans_length)
		get_node("playerShield").fadeout()
		impulse.emit()
		warp_sound_on()

	
func shoot_torpedo():
	if energy_current > torpedo_drain && warpTime == false:
		
		var t = torpedo_scene.instantiate()
		t.global_position = muzzle.global_position
		t.rotation = self.rotation
		t.shooter = "player"
		%TorpedoSound.play()
		emit_signal("torpedo_shot", t)
		if GameSettings.unlimitedEnergy == false:
			energy_current -= torpedo_drain
			playerEnergyChanged.emit(energy_current)


func die():
	if alive == true:
		%PlayerDieSound.play()
		alive = false
		self.visible = false
		hp_current = hp_max
		get_node("playerShield").shieldActive = false
		emit_signal("died") # Connected to "_on_player_died()" in game.gd
		

func respawn(pos):
	if alive==false:
		alive = true
		global_position = pos
		velocity = Vector2.ZERO
		self.visible = true
		hp_current = hp_max #Resets HP
		rotation = 0 #Sets rotation to straight up
		get_node("playerShield").shieldActive = true
		get_node("playerShield").shieldAlive()
		get_node("playerShield").sp_current = get_node("playerShield").sp_max

# Take torpedo damage
func _on_player_area_entered(area):
	if area.is_in_group("torpedo") and area.shooter != "player":
		area.queue_free()
		if GameSettings.unlimitedHealth == false:
			var damage_taken = area.damage
			hp_current -= damage_taken
			playerHealthChanged.emit(hp_current)
		if hp_current <= 0:
			die()
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
	
func teleport(): # Uses coords from cheat menu to teleport player
	global_position = GameSettings.teleportCoords
	velocity = Vector2(0, 0)
	if warping_active == true:
		warping_state_change()
	

#Audio functions
# Movement
func warp_sound_on():
	var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(%ship_idle, "volume_db", -60, 2.0)
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
