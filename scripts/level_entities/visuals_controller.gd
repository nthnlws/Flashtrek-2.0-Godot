extends Node2D
class_name LaserVisualsController

@onready var all_particles:Array[Node] = $Particles.get_children()
@onready var all_sounds:Array[Node] = $Audio.get_children()
@onready var laser:ColorRect = $laser_beam
@onready var hit_effect: Node2D = $laser_beam/LaserHitEffect

@onready var debug_marker: Sprite2D = $laser_beam/DebugTargetMarker

@onready var origin_particles: GPUParticles2D = $Particles/origin_particles
@onready var path_particles: GPUParticles2D = $Particles/path_particles
@onready var target_particles: GPUParticles2D = $Particles/target_particles

@onready var laser_sound: AudioStreamPlayer = $Audio/laserSound
@onready var laser_fizzle: AudioStreamPlayer = $Audio/laserFizzle
@onready var laser_bass: AudioStreamPlayer = $Audio/laserBass
@onready var laser_bass_2: AudioStreamPlayer = $Audio/laserBass2

@export var pixel_cutoff:int = 1200

var fade_tween: Tween

signal fade_out_finished


func _ready() -> void:
	laser.visible = false

func play_idle_effect() -> void: # Instantly turn off
	stop_all_particles()
	stop_all_sounds()
	laser.visible = false


func play_fizzling_effect() -> void:
	stop_all_sounds()
	laser.visible = false
	path_particles.emitting = false
	target_particles.emitting = false
	origin_particles.emitting = true
	laser_fizzle.play()


func play_firing_effect(target_pos:Vector2, exact_collision_point:Vector2) -> void:
	origin_particles.emitting = true
	path_particles.emitting = true
	target_particles.emitting = true
	laser_sound.play()
	laser.visible = true
	
	
	# Start fade-in animation
	_animate_shader_progress(1.0, 0.2)
	update_beam_target(target_pos, exact_collision_point) 
	await fade_tween.finished
	hit_effect.visible = true


func play_disabled_effect() -> void:
	play_idle_effect()


func play_fade_out_animation() -> void:
	# Stop particles
	stop_all_particles()
	# Stop sounds
	stop_all_sounds()
	
	# Start fade-out animation and emit signal when done.
	hit_effect.visible = false
	_animate_shader_progress(0.0, 0.2)
	await fade_tween.finished
	laser.visible = false
	fade_out_finished.emit()


func update_beam_target(target_pos:Vector2, exact_collision_point:Vector2) -> void:
	var length = global_position.distance_to(exact_collision_point)
	laser.material.set_shader_parameter("cutoff_x_percent", length/1200)
	
	path_particles.position.x = length/2
	path_particles.process_material.emission_box_extents = Vector3(length/2, 1.0, 1.0)
	target_particles.global_position = exact_collision_point
	
	debug_marker.global_position = exact_collision_point
	hit_effect.global_position = exact_collision_point


func _animate_shader_progress(end_value:float, duration:float) -> void:
	var current_progress:float = laser.material.get_shader_parameter("progress")
	fade_tween = create_tween()
	fade_tween.tween_property(laser.material, "shader_parameter/progress", end_value, duration).from(current_progress)


func stop_all_particles() -> void:
	for particle:GPUParticles2D in all_particles:
		particle.emitting = false


func stop_all_sounds() -> void:
	for sound:AudioStreamPlayer in all_sounds:
		sound.stop()
