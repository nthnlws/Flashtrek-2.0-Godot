extends BaseTractorBeam
class_name CinematicTractorBeam

# No angle clamping — the beam points directly at the target regardless
# of parent rotation. Used during orbit cutscenes by AnalyzePlanetComponent.

var _target_node: Node2D = null
var _is_cinematic_active: bool = false


func _ready() -> void:
	super._ready()
	# Start invisible — AnalyzePlanetComponent drives activation explicitly
	visuals.visible = false
	hitbox_polygon.disabled = true


func _process(_delta: float) -> void:
	if !_is_cinematic_active:
		return
	if not is_instance_valid(_target_node):
		deactivate()
		return
	update_tractor_beam(_target_node.global_position)


# --- Public API ---

func activate_toward(target: Node2D) -> void:
	#print('activating towards %s' % target.name)
	if not is_instance_valid(target):
		push_warning("CinematicTractorBeam: activate_toward() called with invalid target.")
		return
	_target_node = target
	_is_cinematic_active = true
	_set_beam_enabled(true)


func deactivate() -> void:
	_is_cinematic_active = false
	_target_node = null
	_set_beam_enabled(false)


# --- Override geometry to skip angle clamping ---
# The cinematic beam always points directly at the planet regardless of heading.

func update_tractor_beam(target_position: Vector2) -> void:
	#print("Beam origin: %s" % global_position)
	var new_length: float = target_position.distance_to(global_position)
	var new_scale: float = new_length / 2 / DEFAULT_SIZE
	scale.x = new_scale
	scale.y = min(1.0, new_length / 320.0)

	global_rotation = global_position.angle_to_point(target_position)
