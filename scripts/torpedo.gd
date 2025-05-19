extends Area2D


@onready var animation: AnimatedSprite2D = $explosion_animation
@onready var collision: CollisionShape2D = $CollisionShape2D
@export var damage_indicator: PackedScene
@onready var hit_sound: AudioStreamPlayer2D = $torpedo_hit


@export var speed:int = 1000
@export var energy_cost:int = 10

var animation_finished: bool = false
var sound_finished: bool = false

var moving: bool = true
var shooter: String #Saves the shooter ID so that collision detection does not shoot self
var movement_vector := Vector2(0, -1)

var lifetime_seconds:float = 7.5
var age: float = 0.0

@export var base_damage:int = 15
var damage:float = 15.0#:
	#get:
		#return PlayerUpgrades.DamageAdd + (base_damage * PlayerUpgrades.DamageMult)

func _ready() -> void:
	var parent = get_parent().get_parent()
	if parent.has_method("energy_drain"):
		if GameSettings.unlimitedEnergy == false:
			parent.energy_drain(energy_cost)
		
	
func _process(delta):
	age += delta
	if (self.global_position.x >= GameSettings.borderValue or self.global_position.x < -GameSettings.borderValue or 
		self.global_position.y >= GameSettings.borderValue or self.global_position.y < -GameSettings.borderValue):
			queue_free()
			
	if age > lifetime_seconds:
		queue_free()
	
	if animation_finished and sound_finished:
		queue_free()


func _physics_process(delta):
	if moving:
		global_position += movement_vector.rotated(rotation) * speed * delta


func kill_projectile(target): # Creates explosion animation and kills self
	$Sprite2D.visible = false
	moving = false
	if target == "shield_area":
		animation.play("explode_shield")
	elif target == "hitbox_area":
		animation.play("explode_hull")
	hit_sound.play()
	


func _on_torpedo_collision(area: Area2D) -> void:
	set_deferred("collision.disabled", true)
	var parent = area.get_parent()
	var name = area.name
	if parent.has_method("take_damage"):
		var target = parent.take_damage(damage, self.global_position)
	kill_projectile(name)


func _on_animation_finished() -> void:
	animation_finished = true

func _on_torpedo_hit_finished() -> void:
	sound_finished = true
