extends BaseTractorBeam
class_name ShipTractorBeam

signal object_tractored(object: Node2D)
signal object_released(object: Node2D)
signal energy_drain(amount: float)
signal object_captured(container_data: ContainerData)

var is_input_active: bool = false
## Any Area2D implementing collect_pickup().
var tractored_object: Area2D = null
## Held while the beam button is down, regardless of aim.
var towed_ship: Node2D = null

const MAX_ANGLE_DEVIATION_RAD: float = deg_to_rad(35)
const TOW_DISTANCE: float = 320.0
const TOW_STIFFNESS: float = 4.0
@export var tractor_speed: float = 250.0
@export var energy_drain_rate: float = 10.0


func _ready() -> void:
	super._ready()
	if is_instance_valid(parent_node) and parent_node.has_signal("to_overdrive_transition"):
		parent_node.to_overdrive_transition.connect(_handle_parent_overdrive)


func _physics_process(delta: float) -> void:
	if is_instance_valid(towed_ship):
		_update_tow(delta)
		return

	if is_instance_valid(tractored_object) and beam_active:
		var target_position: Vector2 = global_position

		tractored_object.global_position = tractored_object.global_position.move_toward(
			target_position,
			tractor_speed * delta
		)

		if tractored_object.global_position.distance_to(target_position) < 5.0:
			if tractored_object is ContainerPickup:
				object_captured.emit((tractored_object as ContainerPickup).container_data)
			if tractored_object.has_method("collect_pickup"):
				tractored_object.collect_pickup()
			tractored_object = null


func _process(_delta: float) -> void:
	if not is_input_active:
		return

	if is_instance_valid(towed_ship):
		if not towed_ship.can_be_towed():
			_release_tow()
			return
		_set_beam_enabled(true)
		update_tractor_beam(towed_ship.global_position)
		energy_drain.emit(energy_drain_rate)
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
	_release_tow()
	if beam_active:
		_set_beam_enabled(false)


# --- Towing ---

func _update_tow(delta: float) -> void:
	var heading: Vector2 = Vector2.from_angle(parent_node.global_rotation)
	var tow_point: Vector2 = parent_node.global_position - heading * TOW_DISTANCE
	var weight: float = 1.0 - exp(-TOW_STIFFNESS * delta)
	towed_ship.global_position = towed_ship.global_position.lerp(tow_point, weight)
	towed_ship.global_rotation = lerp_angle(towed_ship.global_rotation, parent_node.global_rotation, weight * 0.5)


func _release_tow() -> void:
	if is_instance_valid(towed_ship):
		object_released.emit(towed_ship)
	towed_ship = null


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
	if is_instance_valid(tractored_object) or is_instance_valid(towed_ship):
		return

	if area.has_method("collect_pickup"):
		tractored_object = area
		object_tractored.emit(area)
		return

	# Hitbox areas are direct children of the ship
	var ship: Node = area.get_parent()
	if ship and ship.has_method("can_be_towed") and ship.can_be_towed():
		towed_ship = ship as Node2D
		object_tractored.emit(towed_ship)


func _on_area_exited(area: Area2D) -> void:
	if area == tractored_object:
		object_released.emit(tractored_object)
		tractored_object = null
