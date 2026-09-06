extends CharacterBody2D
class_name Player

signal to_impulse_transition
signal to_overdrive_transition

# --- Components ---
@onready var energy: EnergyComponent = $EnergyComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var upgrade_modifiers: ShipStatModifiers = ShipStatModifiers.new()
@onready var weapons_component: WeaponsComponent = $WeaponsComponent

# --- Node References ---
@onready var sprite: Sprite2D = $ShipSprite
@onready var sprite_animation: AnimationPlayer = $ShipSprite/SpriteAnimation
@onready var shield: Shield = $Shield
@onready var laser: Laser = $Laser
@onready var camera: Camera2D = $Camera2D
@onready var galaxy_particles: GPUParticles2D = $GalaxyParticles
@onready var galaxy_warp_sound: AudioStreamPlayer = %Galaxy_warp	

# --- Movement Variables ---
var direction: Vector2 = Vector2.ZERO
var overdrive_active: bool = false
var overdrive_multiplier: float = 0.45
var overdrivem_r: float = 1.0
var overdrivem_v: float = 1.0
var trans_length: float = 0.8
var base_scale: Vector2 = Vector2(1.5, 1.5)

# --- State Variables ---
var cloaked: bool = false
var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
var current_cargo: int = 0
var current_tweens: Array[Tween] 
var current_enemy_list: Array[FactionCharacter]

var ship_stats: ShipState
## Tracks if the player is within the communication range
## of a planet. Set by the planet with the changePlanet() function
var nearest_planet: PlanetData

func set_player_direction(joystick_direction) -> void:
	direction = joystick_direction


func _ready() -> void:
	z_index = Utility.Z["Player"]
	$warp_anim.z_index = Utility.Z["Effects"]
	
	_connect_signals()
	sync_ship_to_data(ship_stats)
	SignalBus.player_type_changed.emit.call_deferred(ship_stats)
	
	_set_ship_scale(Vector2(1.5, 1.5))
	
	for weapon in get_tree().get_nodes_in_group("secondary_weapon"):
		weapon.faction = faction


func _connect_signals() -> void:
	SignalBus.teleport_player.connect(teleport)
	SignalBus.player_type_changed.connect(sync_ship_to_data)
	MissionManager.mission_started.connect(_handle_mission_pickup)
	MissionManager.mission_completed.connect(_handle_mission_finish)
	SignalBus.joystickMoved.connect(set_player_direction)
	SignalBus.triggerGalaxyWarp.connect(trigger_galaxy_warp)
	SignalBus.combatantEntered.connect(_handle_new_combatant)
	SignalBus.combatantExited.connect(_handle_exiting_combatant)


func sync_ship_to_data(new_stats: ShipState) -> void:
	self.ship_stats = new_stats
	health_component.upgrades = upgrade_modifiers
	var ship_info: BaseShipInfo = Utility.get_ship_stats(new_stats.ship_type)
	# Sprite / collision setup
	sprite.texture.region = Rect2(ship_info.sprite_coords, Vector2(48, 48))
	shield.scale =  ship_info.shield_scale * base_scale
	weapons_component.firing_position.position.y = ship_info.muzzle_pos * base_scale.y

	var rawColl = ship_info.collision_polygon
	var parsed_array = JSON.parse_string(rawColl)
	var PV2Array = PackedVector2Array()
	for pair in parsed_array:
		PV2Array.append(Vector2(pair[0], pair[1]))
	PV2Array = center_polygon(PV2Array)
	$hitbox_area/CollisionPolygon2D.polygon = PV2Array
	$WorldCollisionShape.polygon = PV2Array

	# Sync health and energy components
	health_component.setMaxHealth(new_stats.scaled_max_HP)
	health_component.setCurrentHealth(health_component.HP_max)
	health_component.setMaxShield(new_stats.scaled_max_shield)
	health_component.setCurrentShield(health_component.SP_max)
	energy.setMaxEnergy(new_stats.scaled_energy)
	energy.setCurrentEnergy(new_stats.scaled_energy)
	weapons_component.damage_multiplier = new_stats.scaled_damage_mult
	faction = new_stats.current_faction


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
	weapons_component.firing_position.position.y *= new_scale.y


func _process(delta: float) -> void:
	if !health_component.alive: return
	
	# Handle Idle Audio
	var is_moving: bool = velocity.length() > 100.0 and Utility.current_gamestate == Utility.GAMESTATE.WARPING
	idle_sound(is_moving)
	
	if !laser.laser_on:
		energy.regenerate(delta, 10.0)
	
	if sprite.material:
		update_shader_region()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"):
		cloak_ship(Utility.FACTION.ROMULAN, true)
	elif event.is_action_pressed("debug2"):
		cloak_ship(Utility.FACTION.ROMULAN, false)
		return
	
	_handle_input_actions(event)


func update_shader_region() -> void:
	var tex = sprite.texture
	if tex is AtlasTexture:
		var atlas_size = tex.atlas.get_size()   # Full spritesheet size (336, 672)
		var region     = tex.region             # pixel offset within the sheet
		var uv_min = Vector2(region.position.x / atlas_size.x,
							 region.position.y / atlas_size.y)

		sprite.material.set_shader_parameter("region_uv_min", uv_min)
	else:
		# uv_min stays (0, 0) when not AtlasTexture
		sprite.material.set_shader_parameter("region_uv_min", Vector2.ZERO)


func _handle_input_actions(event: InputEvent) -> void:
	if event.is_action_pressed("overdrive") and Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		overdrive_state_change(trans_length)


func _physics_process(delta: float) -> void:
	if !health_component.alive: return
	
	_handle_movement(delta)
	move_and_slide()


func _handle_movement(delta: float) -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		var thrust: float = 0.0
		
		if OS.get_name() == "Windows":
			thrust = Input.get_axis("move_backward", "move_forward")
			
		# Apply unified physics
		apply_thrust(thrust, delta)
		
		# Rotation logic remains exactly the same
		if direction.y != 0:
			rotate(deg_to_rad(direction.y * ship_stats.scaled_agility * delta * overdrivem_v))
			
		if OS.get_name() == "Windows":
			if Input.is_action_pressed("rotate_right"):
				rotate(deg_to_rad(ship_stats.scaled_agility * delta * overdrivem_r))
			if Input.is_action_pressed("rotate_left"):
				rotate(deg_to_rad(-ship_stats.scaled_agility * delta * overdrivem_r))

func apply_thrust(thrust: float, delta: float, speed_mult: float = 1.0) -> void:
	if thrust != 0.0:
		velocity += transform.x * thrust * ship_stats.scaled_acceleration * delta / overdrivem_v
		velocity = velocity.limit_length((ship_stats.scaled_speed * speed_mult) / overdrivem_v)
	else:
		# Natural deceleration when no thrust is applied
		velocity = velocity.move_toward(Vector2.ZERO, ship_stats.scaled_acceleration * delta * 0.25)


func overdrive_state_change(transition_length:float) -> void: # Reverses overdrive state
	var is_instant:bool = true if is_zero_approx(transition_length) else false
	if Utility.current_gamestate == Utility.GAMESTATE.CUTSCENE:
		printerr("Cannot change player overdrive state, Utility.current_gamestate is CUTSCENE")
		return
	
	# Stop any ongoing tweens
	for tween: Tween in current_tweens:
		if tween.is_running():
			tween.stop()

	current_tweens.clear() # Clear the list of running tweens
	
	if overdrive_active: # Transition to impulse
		to_impulse_transition.emit()
		energy.lock_regeneration(trans_length / 2)
		overdrive_active = false
		if laser:
			laser.force_enable()
		if is_instant:
			scale = base_scale
			overdrivem_v = 1.0
			overdrivem_r = 1.0
			shield.call_deferred("fadein_SMOOTH")
		else:
			var tween_scale: Object = create_tween() # Ship sprite scale
			tween_scale.tween_property(self, "scale", base_scale, transition_length)
			current_tweens.append(tween_scale)
			
			var tween_v: Object = create_tween() # Max Velocity
			tween_v.tween_property(self, "overdrivem_v", 1.0, transition_length * 4)
			current_tweens.append(tween_v)
			
			var tween_r: Object = create_tween() # Rotation speed
			tween_r.tween_property(self, "overdrivem_r", 1.0, transition_length)
			current_tweens.append(tween_r)
			
			shield.fadein_SMOOTH()
			overdrive_sound_off()
	else: # Transition to overdrive
		to_overdrive_transition.emit()
		overdrive_active = true
		overdrive_sound_on()
		if laser:
			laser.force_disable()
		if is_instant:
			scale = base_scale * Vector2(1.5, 1.0)
			overdrivem_v = overdrive_multiplier
			overdrivem_r = overdrive_multiplier
			shield.fadeout_INSTANT()
		else:
			var tween_scale: Object = create_tween() # Ship sprite scale
			tween_scale.tween_property(self, "scale", base_scale * Vector2(1.5, 1), transition_length)
			current_tweens.append(tween_scale)
			
			var tween_v: Object = create_tween() # Max Velocity
			tween_v.tween_property(self, "overdrivem_v", overdrive_multiplier, transition_length)
			current_tweens.append(tween_v)
			
			var tween_r: Object = create_tween() # Rotation speed
			tween_r.tween_property(self, "overdrivem_r", overdrive_multiplier, transition_length)
			current_tweens.append(tween_r)
			
			shield.fadeout_SMOOTH()



func killPlayer(hit_event: HitEvent) -> void:
	Utility.current_gamestate = Utility.GAMESTATE.SYSTEM
	%PlayerDieSound.play()
	self.visible = false
	shield.fadeout_INSTANT()
	
	if overdrive_active == true:
		overdrive_state_change(0.0) # Instant state change
	
	#Kill player stats
	energy.setCurrentEnergy(0.0)
	
	await get_tree().create_timer(1.5).timeout
	SignalBus.playerDied.emit()


func respawn() -> void:
	if health_component.alive == false:
		health_component.alive = true
		SignalBus.playerRespawned.emit()
		
		velocity = Vector2.ZERO
		self.visible = true
		
		# Restores all HUD values to max
		health_component.resetHealthToMax()
		health_component.resetShieldToMax()
		energy.resetEnergyToMax() # Resets energy
		
		rotation = deg_to_rad(-90.0) # Sets rotation to up
		
		if shield:
			shield.turnShieldOn()
			shield.fadein_INSTANT()
		health_component.regenTimeout = false


func teleport(new_position: Vector2) -> void: # Uses coords from cheat menu to teleport player
	if overdrive_active == true:
		overdrive_state_change(0.0)
	global_position = new_position
	velocity = Vector2(0, 0)


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
	if LevelManager.target_system_data: # Ensure warp has destination
		if LevelManager.current_system_data.system_name != LevelManager.target_system_data.system_name:
			var start_sys_id: int = LevelManager.current_system_data.system_index
			var end_sys_id: int = LevelManager.target_system_data.system_index
			var warp_distance: int = GalaxyData.get_jump_distance(start_sys_id, end_sys_id)
			if warp_distance > ship_stats.scaled_warp_range:
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
				trigger_galaxy_warp()
	else: print("No target system selected")


func trigger_galaxy_warp() -> void:
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
	SignalBus.start_warp_effect.emit()
	create_tween().tween_property(galaxy_particles.process_material, "flatness", 0.0, 5.0)
	create_tween().tween_property(galaxy_particles.process_material, "scale_min", 1.0, 3.5)
	create_tween().tween_property(galaxy_particles.process_material, "scale_max", 2.0, 3.5)
	
	await get_tree().create_timer(2.5).timeout # 8.5 sec
	var tween2: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween2.tween_property(galaxy_warp_sound, "pitch_scale", 2.5, 3.5)
	overdrive_state_change(3.0)
	
	await get_tree().create_timer(2.5).timeout
	trigger_warp_effect(3.0, true)
	
	await get_tree().create_timer(1.0).timeout # 11.5 sec, velocity tween ends
	#create_tween().tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.8)
	create_tween().tween_property(galaxy_particles, "amount_ratio", 0.0, 2.5)
	
	
	await get_tree().create_timer(0.30).timeout
	%warp_boom.play()
	
	await get_tree().create_timer(0.20).timeout
	galaxy_warp_sound.stop()
	
	galaxy_warp_sound.pitch_scale = 1.0
	tween.stop()
	tween2.stop()
	
	await get_tree().create_timer(2.0).timeout
	SignalBus.galaxy_warp_finished.emit(LevelManager.current_system_data)
	Utility.current_gamestate = Utility.GAMESTATE.SYSTEM


func _handle_mission_pickup(mission_data: MissionData) -> void:
	if mission_data.type == MissionData.MISSION_TYPE.DELIVERY:
		current_cargo += 1


func apply_upgrade(pickup: UpgradePickup) -> void:
	SignalBus.playerUpgradeApplied.emit(pickup.upgrade_type)
	const MULT_STEP: float = 0.05 # 5% increase to stat
	
	var type: UpgradePickup.MODULE_TYPES = pickup.upgrade_type
	var modifier: UpgradePickup.MODIFIER = pickup.modifier_type # Mult vs Add
	
	match type:
		UpgradePickup.MODULE_TYPES.SPEED:
			upgrade_modifiers.SpeedMult = upgrade_modifiers.SpeedMult + MULT_STEP
		UpgradePickup.MODULE_TYPES.ROTATION:
			upgrade_modifiers.AgilityMult = upgrade_modifiers.AgilityMult + MULT_STEP
		UpgradePickup.MODULE_TYPES.FIRE_RATE:
			upgrade_modifiers.FireRateMult = upgrade_modifiers.FireRateMult + MULT_STEP
		UpgradePickup.MODULE_TYPES.HEALTH:
			upgrade_modifiers.HullMult = upgrade_modifiers.HullMult + MULT_STEP
			SignalBus.playerMaxHealthChanged.emit(health_component.HP_max)
		UpgradePickup.MODULE_TYPES.SHIELD:
			upgrade_modifiers.ShieldMult = upgrade_modifiers.ShieldMult + MULT_STEP
			if shield: # Manually forces the shield to calculate and signal the new max value
				health_component.setMaxShield(health_component.SP_max)
				SignalBus.playerMaxShieldChanged.emit(health_component.getMaxShield())
		UpgradePickup.MODULE_TYPES.DAMAGE:
			upgrade_modifiers.DamageMult = upgrade_modifiers.DamageMult + MULT_STEP


func trigger_warp_effect(length: float, warp_effect_on: bool) -> void:
	sprite_animation.speed_scale = 2 / length
	if warp_effect_on:
		cloaked = true
		sprite_animation.play("galaxy_warp_out")
	else:
		sprite_animation.play("galaxy_warp_in")
		await sprite_animation.animation_finished
		cloaked = false


func _handle_mission_finish(finished_data: MissionData) -> void:
	if finished_data.type == MissionData.MISSION_TYPE.DELIVERY:
		current_cargo -= 1
		current_cargo = clamp(current_cargo, 0, ship_stats.cargo_capacity)


func _handle_new_combatant(enemy: FactionCharacter) -> void:
	# If adding first combatant to list
	if current_enemy_list.size() == 0:
		SignalBus.entering_combat.emit()
	if !current_enemy_list.has(enemy):
		current_enemy_list.append(enemy)


func _handle_exiting_combatant(enemy: FactionCharacter) -> void:
	# Remove combatant from list
	if enemy in current_enemy_list:
		current_enemy_list.erase(enemy)
	# No active combatants
	if current_enemy_list.is_empty():
		SignalBus.exited_combat.emit()

func cloak_ship(faction: Utility.FACTION, is_cloaking: bool) -> void:
	if faction == Utility.FACTION.ROMULAN:
		if is_cloaking:
			sprite_animation.play("cloak_ROMULAN")
		else:
			sprite_animation.play("uncloak_ROMULAN")
	elif faction == Utility.FACTION.FEDERATION:
		if is_cloaking:
			sprite_animation.play("cloak_FEDERATION")
		else:
			sprite_animation.play("uncloak_FEDERATION")
	elif faction == Utility.FACTION.KLINGON:
		if is_cloaking:
			sprite_animation.play("cloak_KLINGON")
		else:
			sprite_animation.play("uncloak_KLINGON")


func changePlanet(new_comms: PlanetData = null):
	nearest_planet = new_comms
