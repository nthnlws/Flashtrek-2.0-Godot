extends Area2D
class_name HomingMissile

@export var damage_curve: Curve
@export var explosion_radius:int = 150
@export var max_damage:float = 30.0

var energy_drain:float = 20.0
@export var speed:float = 600.0
var winding_amplitude: float = 1100.0 # How wide the wiggles are
var winding_noise: FastNoiseLite


@onready var explosion: AnimatedSprite2D = $explosion_anim
@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var animation_finished: bool = false
var sound_finished: bool = false
var alive: bool = false
var time_alive: float = 0.0

var exceptions: Array = []
var shooterObject: Node #Saves the shooter ID for targeting logic

var starting_pos: Vector2
var target_position: Vector2

var faction:Utility.FACTION = Utility.FACTION.NEUTRAL

signal drain_energy(cost: float)

func _ready() -> void:
	winding_noise = FastNoiseLite.new()
	winding_noise.seed = randi()
	winding_noise.frequency = 1.0
	
	z_index = Utility.Z["Weapons"]
	explosion.animation_finished.connect(delete_self)
	
	collision_shape.shape.radius = explosion_radius
	alive = true
	particles.emitting = true
	
	if GameSettings.unlimitedEnergy == false:
		drain_energy.emit(energy_drain)


func _physics_process(delta: float):
	if alive:
		time_alive += delta
		var direction_to_target = (target_position - global_position).normalized()
		var perpendicular_vector = direction_to_target.orthogonal()
		var homing_velocity = direction_to_target * speed
		var noise_value = winding_noise.get_noise_1d(time_alive)
		var winding_velocity = perpendicular_vector * noise_value * winding_amplitude
		var final_velocity = homing_velocity + winding_velocity

		global_position += final_velocity * delta
		rotation = final_velocity.angle()
		
		if global_position.distance_to(target_position) < 15.0:
			explode()
			return


func explode() -> void:
	alive = false
	sprite.visible = false
	explosion.visible = true
	explosion.play_backwards("explosion")
	particles.emitting = false
	#print("Homing missile exploded at position: ", global_position)
	
	var damage_areas:Array[Area2D] = get_overlapping_areas()
	#print(damage_areas)
	
	var hit_event:HitEvent = create_hit_event()
	for area:Area2D in damage_areas:
		if area.has_method("can_recieve_damage") and !exceptions.has(area):
			apply_damage_to_area(area, hit_event)
			#print("applied damage to %s with parent %s" % [area.name, area.get_parent().name])
	
	await explosion.animation_finished
	explosion.visible = false
	explosion.stop()


func create_hit_event() -> HitEvent:
	# Create HitEvent resource
	var hit_event:HitEvent = HitEvent.new()
	hit_event.shooter_faction = faction
	hit_event.projectile_ID = randi()
	hit_event.hit_position = self.global_position
	if shooterObject:
		hit_event.shooter_instance_id = shooterObject.get_instance_id()
	
	hit_event.is_critical_hit = false
	hit_event.is_continuous_damage = false
	
	return hit_event


func apply_damage_to_area(area:Area2D, hit_event:HitEvent) -> void:
	hit_event.damage_amount = get_explosion_damage(area)
	area.can_recieve_damage(hit_event)


func get_explosion_damage(area) -> float:
	var distance:float
	if area.get_children()[0] is CollisionPolygon2D:
		distance = Utility.get_distance_to_polygon(self.global_position, area)
	elif area.get_children()[0] is CollisionShape2D:
		distance = Utility.get_distance_to_shape(self.global_position, area)
	
	var normalized_distance = min(distance / explosion_radius, 1.0)
	var damage_multiplier = damage_curve.sample(normalized_distance)
	var final_damage = max_damage * damage_multiplier
	
	#print("Dealt %f damage at %f percentage" % [final_damage, damage_multiplier])
	return final_damage


func reset() -> void:
	explosion.stop()
	particles.emitting = false
	sprite.visible = true
	explosion.visible = false


func delete_self() -> void:
	queue_free()
