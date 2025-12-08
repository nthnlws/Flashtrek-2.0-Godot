extends Node2D

var is_out:bool = false
var _active_tween:Tween
const slide_time_sec:float = 0.65
var in_management_state:bool = false

@onready var manage_saves_button: TabButton = $SavesContainer/ManageSaves
func _ready() -> void:
	manage_saves_button.tab_clicked.connect(_toggle_management_state.unbind(1))


func slide_saves_container_out() -> void:
	if _active_tween:
		_active_tween.kill()
	
	is_out = true
	_active_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(self, "position", Vector2(0, 0), slide_time_sec)


func slide_saves_container_in() -> void:
	if _active_tween:
		_active_tween.kill()
	
	is_out = false
	_active_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_active_tween.tween_property(self, "position", Vector2(-390, 0), slide_time_sec)


func _toggle_management_state() -> void:
	#print('manage saves button clicked')
	if in_management_state:
		get_tree().call_group("slot_buttons", "exit_management_state")
		if %PopupContainer.showing:
			%PopupContainer.close_popup()
	else:
		get_tree().call_group("slot_buttons", "enter_management_state")


func _entered_management_state() -> void:
	if in_management_state == false:
		in_management_state = true

func _exited_management_state() -> void:
	if in_management_state == true:
		in_management_state = false
