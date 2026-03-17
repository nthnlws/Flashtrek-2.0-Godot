extends Area2D
class_name Torpedo

signal drain_energy(amount:float)

@onready var animation: AnimatedSprite2D = $explosion_animation
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hit_sound: AudioStreamPlayer2D = $torpedo_hit
@onready var torpedo_fire: AudioStreamPlayer2D = $torpedo_fire

@export var speed:int = 1000
@export var energy_drain:float = 10.0

var animation_finished: bool = false
var hit_sound_finished: bool = false
var fire_sound_finished: bool = false


var alive: bool = true
var exceptions: Array = []
var shooterObject: Node # Saves the shooter ID for targeting logic
var movement_vector: Vector2 = Vector2(1, 0)

var lifetime_seconds:float = 5.0
var age: float = 0.0
var faction: Utility.FACTION

var damage:float = 15.0
var world_border:int = 20000

func _ready() -> void:
	torpedo_fire.pitch_scale = randf_range(0.95, 1.05)
	torpedo_fire.play()
	
	area_entered.connect(_on_torpedo_collision)
	z_index = Utility.Z["Weapons"]
	
	world_border = LevelManager.current_system_data.system_size

	drain_energy.emit(energy_drain)


func _process(delta: float) -> void:
	if alive:
		age += delta
		if (self.global_position.x >= world_border or self.global_position.x < -world_border or 
			self.global_position.y >= world_border or self.global_position.y < -world_border):
				queue_free()
				
		if age > lifetime_seconds:
			queue_free()
		
	elif animation_finished and hit_sound_finished and fire_sound_finished:
			queue_free()


func _physics_process(delta: float) -> void:
	if alive:
		global_position += movement_vector.rotated(rotation) * speed * delta


func kill_projectile(target) -> void: # Creates explosion animation and kills self
	$Sprite2D.visible = false
	if target == "shield_area":
		animation.play("explode_shield")
	elif target == "hitbox_area":
		animation.play("explode_hull")
	hit_sound.play()


func _on_torpedo_collision(area: Area2D) -> void:
	if !exceptions.has(area):
		hit_success(area)

func hit_success(area:Area2D) -> void:
	if not alive:
		return
	
	alive = false
	area_entered.disconnect(_on_torpedo_collision)
	set_deferred("collision.disabled", true)
	var projectile_name = area.name
	
	# Hit event creation
	var hit_event:HitEvent = HitEvent.new()
	hit_event.shooter_faction = faction
	hit_event.projectile_ID = randi()
	hit_event.hit_position = self.global_position
	if shooterObject:
		hit_event.shooter_instance_id = shooterObject.get_instance_id()
		if shooterObject.is_in_group("player"):
			hit_event.is_from_player = true
	
	hit_event.is_critical_hit = false
	hit_event.is_continuous_damage = false
	
	hit_event.damage_amount = damage
	
	if area.has_method("can_recieve_damage") and is_instance_valid(shooterObject):
		area.can_recieve_damage(hit_event)
	kill_projectile(projectile_name)


func _on_animation_finished() -> void:
	animation_finished = true
	animation.visible = false


func _on_torpedo_hit_finished() -> void:
	hit_sound_finished = true


func _on_torpedo_fire_finished() -> void:
	fire_sound_finished = true
