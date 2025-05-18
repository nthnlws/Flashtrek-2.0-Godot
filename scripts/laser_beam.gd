extends Node2D
class_name Laser

signal laserEnded

@onready var laser: ColorRect = $laser_beam
@onready var origin_particles: GPUParticles2D = $origin_particles
@onready var path_particles: GPUParticles2D = $path_particles
@onready var target_particles: GPUParticles2D = $target_particles
@onready var raycast: RayCast2D = $RayCast2D
@onready var parent = get_parent()

@onready var fizzle_sound: AudioStreamPlayer = $Audio/laserFizzle
@onready var laser_sound: AudioStreamPlayer = $Audio/laserSound
@onready var laser_bass: AudioStreamPlayer = $Audio/laserBass
@onready var laser_bass_2: AudioStreamPlayer = $Audio/laserBass2

@export var damage_indicator: PackedScene

@export var base_damage:int = 20
@export var base_energy_drain:float = 7.5
@export var view_distance:int = -1200

const BLUE = Color(0.5, 1.0, 0.96, 1.0)
const GREEN = Color(0.2, 0.432, 0.198, 1.0)
const RED = Color(0.888, 0.362, 0.412, 1.0)
var color: Color = BLUE

var accumulated_damage: float = 0.0
var laserStatus:bool = false
var active_tweens: Array = []
var target: Area2D
var target_point: Vector2
var turning_off:bool = false

func _ready():
	set_laser_color(RED)
	
	raycast.target_position.y = view_distance
	
	SignalBus.playerDied.connect(_handle_death)


func _process(delta: float) -> void:
	if parent is not Player: # Only process for player
		return
		
	if parent.warping_active or Utility.mainScene.in_galaxy_warp:
		if laser.visible and !turning_off: # Turn off laser when warping
			fade_laser_OFF()
			particles_OFF()
		return
	if laserStatus: # Right click is held
		# Energy drain and fizzle
		if parent.has_method("energy_drain"):
			parent.energy_drain(base_energy_drain * delta)
		if parent.has_method("energyTimeout"):
			parent.energyTimeout()
	
		# Laser beam visible
		if target: # If laser has valid target
			var distance: float = self.position.distance_to(target_point) + 25
			particles_ON() # Turn on particles
			if !laser.visible: # Turn on laser beam
				fade_laser_ON()
			_set_laser_distance(distance)
			
			accumulated_damage += base_damage * delta
			if accumulated_damage > 10:
				accumulated_damage = 10
				#var color = _get_laser_color(target.name)
				#Utility.createDamageIndicator(accumulated_damage, Utility.rom_green, target_particles.global_position)
				
				var target_parent = target.get_parent()
				if target_parent.has_method("take_damage"):
					target_parent.take_damage(accumulated_damage, target_particles.global_position)
				
				accumulated_damage = 0
					
			
		else:
			if laser.visible and !turning_off:
				fade_laser_OFF()
			particles_OFF()


func _input(event):
	if parent is not Player: # Only process for player
		return
		
	if Input.is_action_just_pressed("right_click"):
		laserStatus = true
		if target == null and !parent.warping_active and !Utility.mainScene.in_galaxy_warp:
			laser_fizzle_ON()
	
	if Input.is_action_just_released("right_click"):
		laserStatus = false
		if laser.visible:
			particles_OFF()
			fade_laser_OFF()

func _handle_death():
	fade_laser_OFF()
	particles_OFF()
	target = null
	accumulated_damage = 0

func _get_laser_color(target) -> String:
	if target == "shield_area":
		return Utility.damage_blue
	elif target == "hitbox_area":
		return Utility.damage_red
	else: return Utility.damage_red
	

func _set_laser_distance(length):
	laser.material.set_shader_parameter("cutoff_x_pixel", length)
	path_particles.position.y = -length/2
	path_particles.process_material.emission_box_extents = Vector3(1.0, length/2, 1.0)
	target_particles.position.y = -length



func set_laser_color(color):
	laser.material.set_shader_parameter('outline_color', color)
	path_particles.process_material.set_color(BLUE)


func aim_laser(origin:Vector2, target:Vector2):
	var length = origin.distance_to(target)
	laser.size.x = length
	laser.size.y = length


func fade_laser_OFF():
	laserEnded.emit()
	accumulated_damage = 0
	
	laser_sound.stop()
	laser_bass.stop()
	laser_bass_2.stop()
	
	turning_off = true
	# Stop all active tweens
	for tween in active_tweens:
		tween.stop()
		
	var tween: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(laser, "material:shader_parameter/progress", 0, 0.2)
	active_tweens.append(tween)
	
	await tween.finished
	active_tweens.erase(tween)
	laser.visible = false
	turning_off = false

func fade_laser_ON():
	accumulated_damage = 0
	laser_sound.play()
	laser_bass.play()
	laser_bass_2.play()
	
	# Stop all active tweens
	for tween in active_tweens:
		tween.stop()
		
	laser.visible = true
	var tween: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(laser, "material:shader_parameter/progress", 1.0, 0.2)
	active_tweens.append(tween)
	
	await tween.finished
	active_tweens.erase(tween)


func laser_fizzle_ON():
	origin_particles.emitting = true
	if !fizzle_sound.playing:
		fizzle_sound.play()

func particles_ON():
	if !path_particles.emitting and !target_particles.emitting:
		path_particles.emitting = true
		target_particles.emitting = true
		
		path_particles.process_material.emission_box_extents.y = laser.size.x/2

func particles_OFF():
	path_particles.emitting = false
	target_particles.emitting = false
	origin_particles.emitting = false
