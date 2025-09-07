extends Node2D
class_name Laser

enum State { IDLE, FIZZLING, FIRING, FADING_OUT, DISABLED }

var current_state = State.IDLE
var target_node = null
var scale_modifier: Vector2 = Vector2.ONE
var disabled: bool = false
var faction: Utility.FACTION = Utility.FACTION.NEUTRAL

var laser_on:bool = false

@onready var visuals_controller: LaserVisualsController = $VisualsController
@onready var raycast: RayCast2D = $RayCast2D

@export var base_damage: float = 20.0
@export var energy_drain: float = 7.5
@export var cone_size:int = 90
@export var max_range:int = 1200
var accumulated_damage: float = 0.0

signal drained_energy(amount:float)
var firing_button_held:bool = false


func _ready() -> void:
	z_index = Utility.Z["Weapons"]
	
	# Hacky way to invert any scale effects on owner ship
	scale_modifier = self.get_global_transform().get_scale()
	self.scale  = scale/scale_modifier


func _physics_process(delta):
	if !disabled:
		if firing_button_held:
			_aim_at_mouse()
			if can_fire():
				#print('can fire, rotation: %s' % str(fmod((rad_to_deg(rotation) + 90), 360.0)))
				if current_state == State.IDLE:
					start_firing()
			else:
				#print('cant fire, rotation: %s' % str(fmod((rad_to_deg(rotation) + 90), 360.0)))
				if current_state == State.FIRING or current_state == State.FIZZLING:
					stop_firing()
			
		match current_state:
			State.IDLE:
				_state_logic_idle(delta)
			State.FIZZLING:
				_state_logic_fizzling(delta)
			State.FIRING:
				_state_logic_firing(delta)
	
	if current_state in [State.IDLE, State.DISABLED, State.FADING_OUT]:
		if laser_on:
			laser_on = false
	elif current_state in [State.FIZZLING, State.FIRING]:
		if !laser_on:
			laser_on = true


func add_exceptions(exceptions:Array[Node]):
	for area in exceptions:
		raycast.add_exception(area)

func _aim_at_mouse() -> void:
	var mouse_position = get_global_mouse_position()
	look_at(mouse_position)
	rotation = wrapf(rotation, 0, TAU)


func can_fire() -> bool:
	# Hacky magic numbers to check if within +- 90 degrees of player rotation
	#print(rad_to_deg(fmod(rotation, PI)))
	if rotation <= TAU and rotation >= PI:
		return true
	else: return false


func start_firing(): # Transition from IDLE to FIZZLING.
	raycast.enabled = true
	self.visible = true
	if target_node != null:
		_change_state(State.FIRING)
	else:
		_change_state(State.FIZZLING)


func stop_firing(): # Player releases the fire button.
	_change_state(State.FADING_OUT)

func force_disable(): # Called by Player during warp drive or other events.
	disabled = true
	_change_state(State.DISABLED)

func force_enable(): # Called by Player when disabling event ends
	disabled = false
	_change_state(State.IDLE)


func _state_logic_idle(delta):
	pass

func _state_logic_fizzling(delta):
	drained_energy.emit(energy_drain * 0.75 * delta)
	_update_aiming()
	# If target, transition to FIRING state
	if target_node != null:
		_change_state(State.FIRING)
	else:
		_change_state(State.FIZZLING)


func _state_logic_firing(delta):
	var tick_damage_amount:float = base_damage * delta
	var tick_energy_drain_amount:float = energy_drain * delta
	drained_energy.emit(tick_energy_drain_amount)
	
	_update_aiming()
	# If no target, transition back to FIZZLING
	if target_node == null:
		_change_state(State.FIZZLING)
	else: # Accumulate and deal damage
		var parent = target_node.get_parent()
		
		# Hit event creation
		var hit_event = HitEvent.new()
		hit_event.shooter_instance_id = get_parent().get_instance_id()
		hit_event.shooter_faction = faction
		hit_event.hit_position = raycast.get_collision_point()
		
		hit_event.is_critical_hit = false
		hit_event.is_continuous_damage = true
		
		hit_event.damage_amount = tick_damage_amount
		
		
		if parent.has_method("take_damage") and is_instance_valid(target_node):
			parent.take_damage(hit_event)
		# Update visuals
		visuals_controller.update_beam_target(target_node.global_position, raycast.get_collision_point())


func _update_aiming():
	raycast.force_raycast_update()
	if raycast.is_colliding(): #TODO update if check for group name/layer
		target_node = raycast.get_collider()
		#print("target: %s" % target_node.name)
	else:
		target_node = null
		#print("no target")


func _change_state(new_state):
	if current_state == new_state:
		return
	
	# Visual updates
	current_state = new_state
	match new_state:
		State.IDLE:
			visuals_controller.play_idle_effect()
			raycast.enabled = false
		State.FIZZLING:
			visuals_controller.play_fizzling_effect()
		State.FIRING:
			visuals_controller.play_firing_effect(target_node.global_position, raycast.get_collision_point())
		State.FADING_OUT:
			# Called _on_fade_out_finished
			visuals_controller.play_fade_out_animation()
		State.DISABLED:
			visuals_controller.play_disabled_effect()


func _on_fade_out_finished():  # Called by visuals controller when fade-out is done
	_change_state(State.IDLE)
