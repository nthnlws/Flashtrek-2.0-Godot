class_name Enemy extends CharacterBody2D

signal exploded(pos, size, points)
signal player_collision(Area: Area2D)

@export var speed:int= 50
@export var shield_on:bool = true
@onready var starbase = get_node("/root/Game/Starbase")
@onready var player = get_node("/root/Game/Player")

#Enemy health variables
@export var hp_max:int = 50
var hp_current:float = hp_max

var trans_length:float= 0.8

var playerAgro:bool = false
var endPoint:Vector2
var randomMove:bool = false
var enemyTarget:String

func _ready():
	if shield_on == true:
		var shieldScene = preload("res://scenes/enemyShield.tscn")
		var newShield = shieldScene.instantiate()
		add_child(newShield)
	
func _process(delta):
	if hp_current <= 0:
		explode()

func _physics_process(delta):
	if self.visible == false: return
	
	# Movement state setter
	if playerAgro == true:
		playerMovement()
		enemyTarget = "Player"
	elif randomMove == true:
		randomMovement(endPoint)
		enemyTarget = "Random"
	elif self.global_position.distance_to(starbase.global_position) < 1000:
		# Sets random point to move to if too close to center and not agro'd on player
		randomMove = true
		endPoint = Vector2(randi_range(-5000, 5000), randi_range(-5000, 5000))
	elif randomMove == !true and playerAgro == !true:
		starbaseMovement()
		enemyTarget = "Starbase"
	else: print("No matching movement status")

	move_and_slide()


func starbaseMovement():
	var direction = global_position.direction_to(starbase.position) # Sets movement direction to starbase
	velocity = direction.normalized()*speed
	rotateToDirection(direction)
	
func playerMovement():
	var direction = global_position.direction_to(player.global_position) # Sets movement direction to player
	velocity = direction.normalized()*speed
	rotateToDirection(direction)
	
func randomMovement(endPoint): 
	var direction = global_position.direction_to(endPoint) # Sets movement direction to player
	velocity = direction.normalized()*speed
	rotateToDirection(direction)
	if self.global_position.distance_to(endPoint) < 5:
		randomMove = false
	
func rotateToDirection(target_direction: Vector2):
	var target_angle = atan2(target_direction.y, target_direction.x) + deg_to_rad(90)
	var difference = rotation - target_angle
	rotation = lerp_angle(rotation, target_angle, 0.1)

func explode():
	queue_free()
	self.visible = false

func _on_agro_box_area_entered(area):
	if area.is_in_group("player"):
		playerAgro =  true

func _on_agro_box_area_exited(area):
	if area.is_in_group("player"):
		playerAgro =  false # Replace with function body.

func _on_hitbox_area_entered(area):
	if area.is_in_group("torpedo") and area.shooter != "enemy":
		area.queue_free()
		var damage_taken = area.damage
		hp_current -= damage_taken
