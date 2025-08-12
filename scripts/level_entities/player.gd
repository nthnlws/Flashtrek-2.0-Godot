extends CharacterBody2D
class_name Player

@onready var intersection_line: Line2D = $intersection_line

var shoot_cd:bool = false
var shooting_button_held:bool = false # Variable to check if fire button is currently clicked

var alive: bool = true

var overdrive_active:bool = false
var shield_active:bool = false
var energyTime:bool = false
var overdriveTime:bool = false
var energy_regen_speed:int = 10
var shield_on:bool = true

var trans_length:float = 0.8
var base_scale:Vector2 = Vector2(1.0, 1.0)
var direction:Vector2 = Vector2(0, 0)
var overdrive_multiplier:float = 0.45
var overdrivem_r:float = 1.0
var overdrivem_v:float = 1.0

var has_mission: bool = false
var current_mission: Dictionary = {}
var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
var animation_scale:Vector2 = Vector2(1, 1)

const WHITE_FLASH_MATERIAL: ShaderMaterial = preload("res://resources/Materials_Shaders/white_flash.tres")
const TELEPORT_FADE_MATERIAL: ShaderMaterial = preload("res://resources/Materials_Shaders/teleport_material_VERTICAL.tres")

@onready var muzzle:Node2D = $Muzzle
@onready var timer:Timer = $regen_timer
@onready var sprite:Sprite2D = $PlayerSprite
@onready var shield:Node2D = $playerShield
@onready var galaxy_particles:GPUParticles2D = $GalaxyParticles
@onready var galaxy_warp_sound:AudioStreamPlayer = %Galaxy_warp
@onready var animation:AnimationPlayer = $AnimationPlayer
@onready var camera:Camera2D = $Camera2D

@export var damage_indicator: PackedScene
@export var torpedo_scene: PackedScene
var Stats: PlayerUpgrades = PlayerUpgrades.new()
var Reputation: PlayerReputation = PlayerReputation.new()

# Health variables
@export var max_HP: float = 150:
	set(value):
		max_HP = value
		if hp_current > get_max_HP(max_HP): # Reduce current HP if max reduced
			hp_current = value
		SignalBus.playerMaxHealthChanged.emit(get_max_HP(max_HP))
	get:
		return get_max_HP(max_HP)
func get_max_HP(new_value:float) -> float:
	if Stats:
		return new_value * Stats.HullMult
	else:
		return new_value

var hp_current:float = max_HP:
	set(value):
		hp_current = clamp(value, 0, max_HP)
		SignalBus.playerHealthChanged.emit(hp_current)


# Maneuverability variables
var max_speed:float = 750.0:
	get:
		return max_speed * Stats.SpeedMult

var rotation_speed:float = 150.0:
	get:
		return rotation_speed * Stats.RotateMult

var acceleration:float = 6.5:
	get:
		return acceleration * Stats.AccelMult


# Energy system variables
@export var max_energy: float = 150.0:
	set(value):
		max_energy = value
		if energy_current > get_max_energy(max_energy): # Reduce current HP if max reduced
			energy_current = value
		SignalBus.playerMaxEnergyChanged.emit(get_max_energy(max_energy))
	get:
		return get_max_energy(max_energy)
func get_max_energy(new_value:float) -> float:
	if Stats:
		return new_value * Stats.EnergyCapacityMult
	else:
		return new_value

var energy_current:float = max_energy:
	set(value):
		energy_current = clamp(value, 0, max_energy)
		SignalBus.playerEnergyChanged.emit(energy_current)

var rate_of_fire:float = 5.0:
	get:
		return rate_of_fire * Stats.FireRateMult

# Cargo upgrade variables
@export var base_cargo_size: int = 1:
	get:
		return base_cargo_size + Stats.CargoCapacityAdd
var current_cargo:int = 0

@export var warp_range: int = 20:
	set(value):
		warp_range = value
		Navigation.player_range = value
	get:
		return warp_range + Stats.WarpRangeAdd


func set_player_direction(joystick_direction) -> void:
	direction = joystick_direction


func _ready() -> void:
	# Signal setup
	SignalBus.player_type_changed.connect(_sync_data_to_resource)
	SignalBus.player_type_changed.connect(_sync_stats_to_resource)
	SignalBus.missionAccepted.connect(mission_accept)
	SignalBus.finishMission.connect(mission_finish)
	SignalBus.joystickMoved.connect(set_player_direction)
	SignalBus.playerDied.connect(clear_mission)
	SignalBus.teleport_player.connect(teleport)
	SignalBus.triggerGalaxyWarp.connect(galaxy_warp_out.unbind(1))
	
	z_index = Utility.Z["Player"]
	var spawn_options: Array = get_tree().get_nodes_in_group("player_spawn_area")
	self.global_position = spawn_options[0].global_position
	
	sprite.material.set("shader_parameter/flash_value", 0.0)
	$warp_anim.z_index = Utility.Z["Effects"]
	
	_sync_data_to_resource(Utility.SHIP_TYPES.Hideki_Class)
	_sync_stats_to_resource(Utility.SHIP_TYPES.Hideki_Class)
	
	_set_ship_scale(Vector2(1.5, 1.5))
	
	call_deferred("initialize_hud_values")


func initialize_hud_values() -> void:
	SignalBus.playerMaxEnergyChanged.emit(max_energy)
	SignalBus.playerEnergyChanged.emit(energy_current)
	SignalBus.playerMaxHealthChanged.emit(max_HP)
	SignalBus.playerHealthChanged.emit(hp_current)


func _sync_data_to_resource(ship:Utility.SHIP_TYPES) -> void:
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


func _sync_stats_to_resource(ship:Utility.SHIP_TYPES) -> void:
	var ship_stats:Dictionary = Utility.PLAYER_SHIP_STATS.values()[ship]
	
	max_speed = ship_stats.SPEED
	rotation_speed = ship_stats.ROTATION_SPEED
	max_HP = ship_stats.MAX_HP
	shield.sp_max = ship_stats.MAX_SHIELD
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
	if !alive: return
	
	if GameSettings.speedOverride == true:
		max_speed = GameSettings.maxSpeed
	else:
		max_speed = max_speed

	# Movement check for idle audio
	if abs(velocity.x)+abs(velocity.y)>100 and Navigation.in_galaxy_warp:
		idle_sound(true)
	else:
		idle_sound(false)
		
	if !$Laser.laserStatus and !energyTime:
		if energy_current < max_energy:
			energy_current += energy_regen_speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		shooting_button_held = true
	if event.is_action_released("left_click"):
		shooting_button_held = false


func _physics_process(delta: float) -> void:
	if !alive or GameSettings.menuStatus == true: return
	
	if Input.is_action_just_pressed("overdrive"):
		if Navigation.in_galaxy_warp == false:
			overdrive_state_change("SMOOTH")

	if shooting_button_held:
		if !shoot_cd:
			if !overdrive_active:
				shoot_cd = true
				shoot_torpedo()
				await get_tree().create_timer(1/rate_of_fire).timeout
				shoot_cd = false
				
	_handle_movement(delta)

	move_and_slide()


func _handle_movement(delta: float) -> void:
	if Navigation.in_galaxy_warp == false:
	# Check for keyboard input (Windows) and add to direction
		if OS.get_name() == "Windows":
			direction.y = Input.get_axis("move_forward", "move_backward")  # Forward/backward movement

		# Add joystick direction for Android or hybrid control
		#direction += direction
		#print(direction)
		# Apply forward/backward thrust logic
		if direction.y != 0:
			velocity += Vector2(0, direction.y).rotated(rotation) * acceleration / overdrivem_v
			velocity = velocity.limit_length(max_speed/overdrivem_v)
		else:
			# Gradually slow down when no input
			velocity = velocity.move_toward(Vector2.ZERO, 3)
			
		if direction.x !=0:
			rotate(deg_to_rad(direction.x * rotation_speed * delta * overdrivem_v))
		
		# Handle rotation for keyboard input
		if OS.get_name() == "Windows":
			if Input.is_action_pressed("rotate_right"):
				rotate(deg_to_rad(rotation_speed * delta * overdrivem_r))
			if Input.is_action_pressed("rotate_left"):
				rotate(deg_to_rad(-rotation_speed * delta * overdrivem_r))


var current_tweens: Array = []
func overdrive_state_change(speed) -> void: # Reverses overdrive state
	# Stop any ongoing tweens
	for tween:Tween in current_tweens:
		if tween.is_running():
			tween.stop()

	current_tweens.clear()  # Clear the list of running tweens
	
	if overdrive_active: # Transition to impulse
		overdriveTimeout()
		overdrive_active = false
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
	else: # Overdrive on transition
		overdrive_active = true
		overdrive_sound_on()
		match speed:
			"INSTANT":
				scale = base_scale * Vector2(1, 1.70)
				overdrivem_v = overdrive_multiplier
				overdrivem_r = overdrive_multiplier
				shield.fadeout_INSTANT()
			"SMOOTH":
				var tween_scale: Object = create_tween() # Ship sprite scale
				tween_scale.tween_property(self, "scale", base_scale * Vector2(1, 1.70), trans_length)
				current_tweens.append(tween_scale)
				
				var tween_v: Object = create_tween() # Max Velocity
				tween_v.tween_property(self, "overdrivem_v", overdrive_multiplier, trans_length)
				current_tweens.append(tween_v)
				
				var tween_r: Object = create_tween() # Rotation speed
				tween_r.tween_property(self, "overdrivem_r", overdrive_multiplier, trans_length)
				current_tweens.append(tween_r)
				
				shield.fadeout_SMOOTH()


func shoot_torpedo() -> void:
	var t: Area2D = torpedo_scene.instantiate()
	if energy_current > t.energy_cost and overdriveTime == false and Navigation.in_galaxy_warp == false:
		t.position = muzzle.global_position
		t.rotation = self.rotation
		t.z_index = 0
		t.drain_energy.connect(energy_drain)
		t.damage = t.damage * Stats.DamageMult
		
		t.set_collision_layer_value(9, true) # Sets layer to player projectile
		t.set_collision_mask_value(3, true) # Turns on enemy hitbox detection
		t.set_collision_mask_value(8, true) # Turns on enemy shield detection
		
		%HeavyTorpedo.pitch_scale = randf_range(0.95, 1.05)
		%HeavyTorpedo.play()
		$Projectiles.add_child(t)


func energy_drain(energy: float) -> void:
	energy_current -= energy


func killPlayer() -> void:
	if alive:
		Navigation.in_galaxy_warp = false
		%PlayerDieSound.play()
		alive = false
		self.visible = false
		shield.shieldActive = false
		
		if overdrive_active == true:
			overdrive_state_change("INSTANT")
		
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
		shield.sp_current = shield.sp_max #Resets Shield
	
		rotation = 0 #Sets rotation to north
		
		shield.turnShieldOn()

		shield.damageTime = false


func energyTimeout() -> void: #Turns of5f energy regen for 1 second after firing laser
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


func overdriveTimeout() -> void: #Turns off torpedo shooting for half of trans_length after leaving overdrive
	overdriveTime = true
	await get_tree().create_timer(trans_length/2).timeout
	overdriveTime = false


func teleport(position:Vector2) -> void: # Uses coords from cheat menu to teleport player
	global_position = position
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

#Weapons
func take_damage(damage:float, hit_pos: Vector2) -> void:
	if Navigation.in_galaxy_warp == false:
		hp_current -= damage # Take damage
		Utility.createDamageIndicator(damage, Utility.damage_red, hit_pos)
		
		if hp_current <= 0:
			killPlayer()


func _teleport_shader_toggle(toggle: String) -> void:
	if toggle == "cloak":
		sprite.material = TELEPORT_FADE_MATERIAL
		var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(sprite.material, "shader_parameter/progress", 1.0, 4.0)
	elif toggle == "uncloak":
		sprite.material = TELEPORT_FADE_MATERIAL
		var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(sprite.material, "shader_parameter/progress", 0.0, 4.0)


func velocity_check() -> bool:
	# Check velocity warp criteria
	var base_check = (
		!Navigation.in_galaxy_warp and
		velocity.x > -100 and velocity.x < 100 and
		velocity.y > -100 and velocity.y < 100 and
		!overdrive_active
	)
	
	if not base_check:
		return false
	else: return true


func galaxy_warp_out() -> void:
	SignalBus.entering_galaxy_warp.emit()
	Navigation.in_galaxy_warp = true
	
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
	create_tween().tween_property(camera, "zoom", Vector2(0.4, 0.4), trans_length/overdrive_multiplier*3)
	
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


func clear_mission() -> void:
	current_mission.clear()
	has_mission = false
	current_cargo = max(0, current_cargo - 1)
	
	
func mission_finish() -> void:
	if !current_mission.is_empty():
		var points:int = current_mission["reward"]
		var faction:Utility.FACTION = Navigation.get_faction_for_system(current_mission.system)
		SignalBus.updateScore.emit(points)
		match faction:
			Utility.FACTION.FEDERATION:
				SignalBus.reputationChanged.emit(Utility.FACTION.FEDERATION, Reputation.FederationRep + points)
			Utility.FACTION.KLINGON:
				SignalBus.reputationChanged.emit(Utility.FACTION.KLINGON, Reputation.KlingonRep + points)
			Utility.FACTION.ROMULAN:
				SignalBus.reputationChanged.emit(Utility.FACTION.ROMULAN, Reputation.RomulanRep + points)
			Utility.FACTION.NEUTRAL:
				SignalBus.reputationChanged.emit(Utility.FACTION.NEUTRAL, Reputation.NeutralRep + points)
		current_mission.clear()
		
	has_mission = false
	current_cargo = max(0, current_cargo - 1)


func create_damage_indicator(damage:float, shooter:String, projectile:Area2D) -> void:
	var spawn: Marker2D = projectile.create_damage_indicator(damage, $hitbox_area.name)
	projectile.kill_projectile($hitbox_area.name)
	$Hitmarkers.add_child(spawn)


func _on_laser_ended() -> void:
	create_damage_indicator


func apply_upgrade(pickup: UpgradePickup) -> void:
	var mult_step:float = 0.05 # 5% increase to stat
	
	var type: UpgradePickup.MODULE_TYPES = pickup.upgrade_type
	var modifier: UpgradePickup.MODIFIER = pickup.modifier_type
	
	match type:
		UpgradePickup.MODULE_TYPES.SPEED:
			Stats.SpeedMult = Stats.SpeedMult + mult_step
		UpgradePickup.MODULE_TYPES.ROTATION:
			Stats.RotateMult = Stats.RotateMult + mult_step
		UpgradePickup.MODULE_TYPES.FIRE_RATE:
			Stats.FireRateMult = Stats.FireRateMult + mult_step
		UpgradePickup.MODULE_TYPES.HEALTH:
			Stats.HullMult = Stats.HullMult + mult_step
		UpgradePickup.MODULE_TYPES.SHIELD:
			Stats.ShieldMult = Stats.ShieldMult + mult_step
			if shield: # Manually forces the shield to calculate and signal the new max value
				shield.sp_max = shield.sp_max
		UpgradePickup.MODULE_TYPES.DAMAGE:
			Stats.DamageMult = Stats.DamageMult + mult_step
