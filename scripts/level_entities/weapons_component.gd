extends Node
class_name WeaponsComponent

@export var is_on_player: bool = false

@export_category("LinkedNodes")
@export var parent_entity: CharacterBody2D
@export var energy_component: EnergyComponent
@export var shield: Node2D
@export var hitbox: HullDamageReceiver
@export var firing_position: Marker2D
@export var tractor_beam: ShipTractorBeam
@export_category("PackedScenes")
@export var torpedo_scene: PackedScene
@export var missile_scene: PackedScene

@onready var cooldown_timer: Timer = $cooldown_timer


var shooting_button_held: bool = false
#var ship_damage_multiplier: float = 1.0
var base_rate_of_fire: float = 5.0
var rate_of_fire: float = 1.0 / base_rate_of_fire:
	set(value):
		cooldown_timer.wait_time = 1.0 / value
		rate_of_fire = value
	#get: return base_rate_of_fire * stats.FireRateMult
var ship_damage_multiplier: float

var stats: PlayerUpgrades = PlayerUpgrades.new()

func _ready() -> void:
	cooldown_timer.wait_time = rate_of_fire
	if tractor_beam:
		tractor_beam.object_captured.connect(_handle_container_pickup)


func _physics_process(delta: float) -> void:
	if !is_on_player: return # Exit if not player
	
	if shooting_button_held and cooldown_timer.is_stopped():
		var mouse_angle: float = firing_position.global_position.angle_to_point(firing_position.get_global_mouse_position())
		var angle_diff: float = angle_difference(parent_entity.rotation, mouse_angle)
		const MAX_AIM_DEVIATION: float = deg_to_rad(35.0)
		
		if abs(angle_diff) <= MAX_AIM_DEVIATION:
			attempt_primary_fire(mouse_angle)


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


func attempt_primary_fire(fire_direction: float) -> void:
	var bullet: Torpedo = torpedo_scene.instantiate()
	var cost: float = bullet.energy_drain

	if _can_fire(cost):
		cooldown_timer.start()
		
		bullet.global_position = firing_position.global_position
		bullet.rotation = fire_direction
		bullet.shooterObject = parent_entity
		bullet.damage *= stats.DamageMult
		bullet.damage_multipler = ship_damage_multiplier
		bullet.faction = parent_entity.faction
		
		bullet.exceptions.append(hitbox)
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
		missile.exceptions.append(hitbox)
		missile.exceptions.append(shield.get_node("shield_area"))
		missile.shooterObject = parent_entity
		missile.max_damage = missile.max_damage * stats.DamageMult
		missile.damage_multiplier = ship_damage_multiplier
		missile.faction = parent_entity.faction
		missile.target_position = clicked_pos
		
		if energy_component:
			energy_component.consume_energy(cost)
			energy_component.lock_regeneration(1.0) # 1 second
		
		%HeavyTorpedo.pitch_scale = randf_range(0.95, 1.05)
		%HeavyTorpedo.play()
		add_child(missile)
	else:
		missile.queue_free()


func _can_fire(cost: float) -> bool:
	var check: bool = false
	if is_on_player: # Player specific checks
		#print("Timer running: %s" % !cooldown_timer.is_stopped())
		#print("Enough energy: %s" % energy_component.request_consume(cost))
		#print('Valid gamestate: %s' % true if Utility.current_gamestate == Utility.GAMESTATE.SYSTEM else false)
		check = (!parent_entity.overdrive_active and !parent_entity.cloaked
				and cooldown_timer.is_stopped()
				and energy_component.request_consume(cost)
				and Utility.current_gamestate == Utility.GAMESTATE.SYSTEM)
	else: # Generic checks
				check = (energy_component.request_consume(cost)
				and cooldown_timer.is_stopped()
				and Utility.current_gamestate == Utility.GAMESTATE.SYSTEM)
	return check


func _handle_container_pickup(data: ContainerData) -> void:
	#print('picked up container')
	if data.is_mission_goal == true:
		#print('attempting mission finish')
		MissionManager.complete_mission()
