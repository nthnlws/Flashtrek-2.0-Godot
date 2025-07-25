extends Area2D

signal drain_energy(amount:int)

@onready var animation: AnimatedSprite2D = $explosion_animation
@onready var collision: CollisionShape2D = $CollisionShape2D
@export var damage_indicator: PackedScene
@onready var hit_sound: AudioStreamPlayer2D = $torpedo_hit

@export var speed:int = 1000
@export var energy_cost:int = 10

var animation_finished: bool = false
var sound_finished: bool = false

var alive: bool = true
var shooter: String #Saves the shooter ID so that collision detection does not shoot self
var movement_vector := Vector2(0, -1)

var lifetime_seconds:float = 7.5
var age: float = 0.0

var damage:float = 15.0

func _ready() -> void:
	area_entered.connect(_on_torpedo_collision)
	z_index = Utility.Z["Projectiles"]

	if GameSettings.unlimitedEnergy == false:
		drain_energy.emit(energy_cost)


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
	if not alive: return
	
	alive = false
	area_entered.disconnect(_on_torpedo_collision)
	set_deferred("collision.disabled", true)
	
	var parent = area.get_parent()
	var name = area.name
	if parent.has_method("take_damage"):
		parent.take_damage(damage, self.global_position)
	kill_projectile(name)


func _on_animation_finished() -> void:
	animation_finished = true


func _on_torpedo_hit_finished() -> void:
	sound_finished = true
