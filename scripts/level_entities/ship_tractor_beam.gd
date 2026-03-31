extends BaseTractorBeam
class_name ShipTractorBeam

signal object_tractored(object: Node2D)
signal object_released(object: Node2D)
signal energy_drain(amount: float)
signal object_captured(container_data: ContainerData)

var is_input_active: bool = false
var tractored_container: Area2D = null

const MAX_ANGLE_DEVIATION_RAD: float = deg_to_rad(35)
@export var tractor_speed: float = 250.0
@export var energy_drain_rate: float = 10.0


func _ready() -> void:
	super._ready()
	if is_instance_valid(parent_node) and parent_node.has_signal("to_overdrive_transition"):
		parent_node.to_overdrive_transition.connect(_handle_parent_overdrive)


func _physics_process(delta: float) -> void:
	if is_instance_valid(tractored_container) and beam_active:
		var target_position: Vector2 = global_position

		tractored_container.global_position = tractored_container.global_position.move_toward(
			target_position,
			tractor_speed * delta
		)

		if tractored_container.global_position.distance_to(target_position) < 5.0:
			object_captured.emit(tractored_container.container_data)
			SignalBus.containerPickedUp.emit(tractored_container)
			tractored_container.queue_free()
			tractored_container = null


func _process(_delta: float) -> void:
	if not is_input_active:
		return

	var target_position: Vector2 = get_global_mouse_position()
	var is_currently_valid: bool = is_aim_valid(parent_node.global_rotation, target_position)

	if is_currently_valid and not beam_active:
		_set_beam_enabled(true)
	elif not is_currently_valid and beam_active:
		_set_beam_enabled(false)

	if beam_active:
		update_tractor_beam(target_position)
		energy_drain.emit(energy_drain_rate)


# --- Public API ---

func try_activate_beam() -> void:
	is_input_active = true


func deactivate_beam() -> void:
	is_input_active = false
	if beam_active:
		_set_beam_enabled(false)


# --- Aim Validation ---

func is_aim_valid(parent_rotation_rad: float, target_position: Vector2) -> bool:
	var origin_position: Vector2 = parent_node.global_position

	var length: float = origin_position.distance_to(target_position)
	var is_length_valid: bool = length <= MAX_BEAM_LENGTH

	var desired_angle_rad: float = origin_position.angle_to_point(target_position)
	var angle_diff: float = angle_difference(parent_rotation_rad, desired_angle_rad)
	var is_angle_valid: bool = abs(angle_diff) <= MAX_ANGLE_DEVIATION_RAD

	return is_length_valid and is_angle_valid


# --- Signals ---

func _handle_parent_overdrive() -> void:
	deactivate_beam()


func _on_area_entered(area: Area2D) -> void:
	if tractored_container:
		return
	if area is ContainerPickup:
		tractored_container = area
		object_tractored.emit(tractored_container.container_data)


func _on_area_exited(area: Area2D) -> void:
	if area == tractored_container:
		object_released.emit(tractored_container.container_data)
		tractored_container = null
