extends Area2D
class_name Torpedo

signal drain_energy(amount:float)

@onready var animation: AnimatedSprite2D = $explosion_animation
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hit_sound: AudioStreamPlayer2D = $torpedo_hit

@export var speed:int = 1000
@export var energy_drain:float = 10.0

var animation_finished: bool = false
var sound_finished: bool = false

var alive: bool = true
var exceptions: Array = []
var shooterObject: Node # Saves the shooter ID for targeting logic
var movement_vector: Vector2 = Vector2(1, 0)

var lifetime_seconds:float = 7.5
var age: float = 0.0
var faction: Utility.FACTION

var damage:float = 15.0

func _ready() -> void:
	area_entered.connect(_on_torpedo_collision)
	z_index = Utility.Z["Weapons"]

	if GameSettings.unlimitedEnergy == false:
		drain_energy.emit(energy_drain)


func _process(delta: float) -> void:
	if alive:
		age += delta
		if (self.global_position.x >= GameSettings.borderValue or self.global_position.x < -GameSettings.borderValue or 
			self.global_position.y >= GameSettings.borderValue or self.global_position.y < -GameSettings.borderValue):
				queue_free()
				
		if age > lifetime_seconds:
			queue_free()
		
	elif animation_finished and sound_finished:
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
	#await hit_sound.finished


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


func _on_torpedo_hit_finished() -> void:
	sound_finished = true
