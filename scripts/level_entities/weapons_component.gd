extends Node
class_name WeaponsComponent

@export var is_on_player: bool = false
@export var apply_randomness: bool = false
@export var accuracy_cone_angle: float = 3.0 # In degrees
@export var base_rate_of_fire: float = 5.0
@export var max_valid_angle: float = 35.0
@export var damage_multiplier: float = 1.0
 
@export_category("Linked Nodes")
@export var parent_entity: CharacterBody2D
@export var energy_component: EnergyComponent
@export var shield: Shield
@export var hitbox: HullDamageReceiver
@export var firing_position: Marker2D
@export var tractor_beam: ShipTractorBeam
#@export_group("AI Settings")

@export_group("PackedScenes")
@export var torpedo_scene: PackedScene = preload("uid://dkwrosj64i8ur")
@export var missile_scene: PackedScene = preload("uid://dj5rx83i8si03")

@onready var cooldown_timer: Timer = $cooldown_timer

var shooting_button_held: bool = false
#var ship_damage_multiplier: float = 1.0
var rate_of_fire: float = 1.0 / base_rate_of_fire:
	set(value):
		cooldown_timer.wait_time = 1.0 / value
		rate_of_fire = value


func _ready() -> void:
	cooldown_timer.wait_time = rate_of_fire
	if tractor_beam:
		tractor_beam.object_captured.connect(_handle_container_pickup)


func _physics_process(delta: float) -> void:
	if !is_on_player: return # Exit if not player
	
	if shooting_button_held and cooldown_timer.is_stopped():
		var firing_position: Vector2 = firing_position.get_global_mouse_position()
		attempt_primary_fire(firing_position)


func _unhandled_input(event: InputEvent) -> void:
	if !is_on_player: return # Exit if not player
	
	# Primary weapon firing
	if event.is_action_pressed("left_click"):
		shooting_button_held = true
	if event.is_action_released("left_click"):
		shooting_button_held = false
	
	if tractor_beam:
		if event.is_action_pressed("right_click"):
			if _can_fire(0): # Try "can fire" with 0 energy cost
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


func attempt_primary_fire(target_location: Vector2) -> void:
	var bullet: Torpedo = torpedo_scene.instantiate()
	var cost: float = bullet.energy_drain
	
	var firing_angle: float = firing_position.global_position.angle_to_point(target_location)
	var angle_diff: float = angle_difference(parent_entity.rotation, firing_angle)
	# Early exit for invalid shooting angle
	if abs(angle_diff) > deg_to_rad(max_valid_angle): return
	
	if apply_randomness:
		target_location = randomize_position(target_location)
		# Recalculate firing angle after randomization
		firing_angle = firing_position.global_position.angle_to_point(target_location)
	
	if _can_fire(cost):
		cooldown_timer.start()
		bullet.global_position = firing_position.global_position
		bullet.rotation = firing_angle
		bullet.shooterObject = parent_entity
		bullet.damage *= damage_multiplier
		bullet.damage_multipler = damage_multiplier
		bullet.faction = parent_entity.faction
		
		if hitbox:
			bullet.exceptions.append(hitbox)
		if shield:
			bullet.exceptions.append(shield.get_node("shield_area"))
		
		if energy_component:
			energy_component.consume_energy(cost)
			energy_component.lock_regeneration(0.5)
		
		add_child(bullet)
	else:
		bullet.queue_free()


func shoot_missile(clicked_pos: Vector2) -> void:
	var missile: HomingMissile = missile_scene.instantiate()
	var cost: float = missile.energy_drain
	
	if _can_fire(cost):
		missile.position = self.global_position
		missile.rotation = self.rotation
		missile.shooterObject = parent_entity
		missile.max_damage = missile.max_damage * damage_multiplier
		missile.damage_multiplier = damage_multiplier
		missile.faction = parent_entity.faction
		missile.target_position = clicked_pos
		
		if is_instance_valid(energy_component):
			energy_component.consume_energy(cost)
			energy_component.lock_regeneration(1.0) # 1 second
		
		if is_instance_valid(hitbox):
			missile.exceptions.append(hitbox)
		if is_instance_valid(shield):
			missile.exceptions.append(shield.get_node("shield_area"))
		
		%HeavyTorpedo.pitch_scale = randf_range(0.95, 1.05)
		%HeavyTorpedo.play()
		add_child(missile)
	else:
		missile.queue_free()


func randomize_position(predicted_position: Vector2) -> Vector2:
	var distance: float = firing_position.global_position.distance_to(predicted_position)
	var max_radius: float = distance * tan(deg_to_rad(accuracy_cone_angle))
	var random_offset: Vector2 = Vector2.from_angle(randf() * TAU) * sqrt(randf()) * max_radius
	
	return predicted_position + random_offset


func _can_fire(cost: float) -> bool:
	# 1. Universal early exits
	if Utility.current_gamestate != Utility.GAMESTATE.SYSTEM:
		return false
		
	if not cooldown_timer.is_stopped():
		return false
		
	# 2. Player-specific early exits
	if is_on_player and (parent_entity.overdrive_active or parent_entity.cloaked):
		return false
		
	# 3. Final check: Energy consumption
	if energy_component:
		return energy_component.request_consume(cost)
		
	# 4. If there's no energy component and all other checks passed, they can fire
	return true


func _handle_container_pickup(data: ContainerData) -> void:
	#print('picked up container')
	if data.is_mission_goal == true:
		#print('attempting mission finish')
		MissionManager.complete_mission()
