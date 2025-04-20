extends Area2D


@onready var animation: AnimatedSprite2D = $explosion_animation
@onready var collision: CollisionShape2D = $CollisionShape2D
@export var damage_indicator: PackedScene


@export var speed:int = 1000
@export var energy_drain:int = 10

var moving: bool = true
var shooter: String #Saves the shooter ID so that collision detection does not shoot self
var movement_vector := Vector2(0, -1)

var lifetime_seconds:float = 7.5
var age: float = 0.0

@export var base_damage:int = 15
var damage:float = 15.0#:
	#get:
		#return PlayerUpgrades.DamageAdd + (base_damage * PlayerUpgrades.DamageMult)

func _process(delta):
	age += delta
	if (self.global_position.x >= GameSettings.borderValue or self.global_position.x < -GameSettings.borderValue or 
		self.global_position.y >= GameSettings.borderValue or self.global_position.y < -GameSettings.borderValue):
			queue_free()
			
	if age > lifetime_seconds:
		queue_free()


func _physics_process(delta):
	if moving:
		global_position += movement_vector.rotated(rotation) * speed * delta

func kill_projectile(target): # Creates explosion animation and kills self
	$Sprite2D.visible = false
	create_damage_indicator(damage, target)
	moving = false
	if target == "shield_area":
		animation.play("explode_shield")
	elif target == "hitbox_area":
		animation.play("explode_hull")
	await animation.animation_finished
	queue_free()
	


func _on_torpedo_collision(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.has_method("take_damage") and area.name != "AgroBox":
		var target = parent.take_damage(damage, shooter, self)


func create_damage_indicator(damage_taken:float, target:String):
	var damage: Marker2D = damage_indicator.instantiate()
	if target == "shield_area":
		var color: String = Utility.damage_blue
		damage.find_child("Label").text = color + str(damage_taken)
	if target == "hitbox_area":
		var color: String = Utility.damage_red
		damage.find_child("Label").text = color + str(damage_taken)
	damage.global_position = self.global_position
	return damage
