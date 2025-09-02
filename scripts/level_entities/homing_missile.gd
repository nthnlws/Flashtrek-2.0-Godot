extends Area2D
class_name HomingMissile

@export var explosion_radius:int = 50
var energy_cost:float = 20.0
var max_damage:float = 30.0
var speed:float = 600.0
@export var winding_amplitude: float = 1100.0 # How wide the wiggles are
@export var winding_noise: FastNoiseLite
@export var damage_curve: Curve

var animation_finished: bool = false
var sound_finished: bool = false
var alive: bool = false
var time_alive: float = 0.0

var exceptions: Array = []
var shooterObject: Node #Saves the shooter ID for targeting logic

var starting_pos: Vector2
var target_position: Vector2

signal drain_energy(cost: float)

func _ready() -> void:
	z_index = Utility.Z["Weapons"]
	
	if GameSettings.unlimitedEnergy == false:
		drain_energy.emit(energy_cost)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		alive = true
		target_position = get_viewport().get_mouse_position()
		print(target_position)


func _physics_process(delta: float):
	if alive:
		if global_position.distance_to(target_position) < 10.0:
			explode()
			return
		
		time_alive += delta
		var direction_to_target = (target_position - global_position).normalized()
		var perpendicular_vector = direction_to_target.orthogonal()
		var homing_velocity = direction_to_target * speed
		var noise_value = winding_noise.get_noise_1d(time_alive)
		var winding_velocity = perpendicular_vector * noise_value * winding_amplitude
		var final_velocity = homing_velocity + winding_velocity

		global_position += final_velocity * delta
		rotation = final_velocity.angle() + (PI/2)
	

func explode() -> void:
	alive = false
	print("Homing missile exploded at position: ", global_position)
