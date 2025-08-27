extends TextureRect

@export var showing: bool = true
@export var transition_time:float = 0.8
const HIDDEN_POS:Vector2 = Vector2(0, -51)
const SHOWN_POS:Vector2 = Vector2.ZERO

var tween: Tween
var total_distance: float = 51

func _ready() -> void:
	if showing == false:
		position = HIDDEN_POS


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("Tab"):
			if showing:
				showing = false
				tween_menu(HIDDEN_POS)
			else:
				showing = true
				tween_menu(SHOWN_POS)


func tween_menu(target_position:Vector2) -> void: # Collapse mission menu
	# Stop running tween
	if is_instance_valid(tween):
		tween.kill()
	
	var distance_to_go = abs(position.distance_to(target_position))
	var travel_fraction = 0.0
	if total_distance > 0:
		travel_fraction = distance_to_go / total_distance
	var dynamic_duration = transition_time * travel_fraction
	
	tween = create_tween()
	tween.tween_property(self, "position", target_position, dynamic_duration)
