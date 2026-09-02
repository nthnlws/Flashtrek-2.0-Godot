extends Control
class_name CommsUI

@onready var comms_message: RichTextLabel = $CommsMessage
@onready var interact_button: TextButton = $InteractButton

const ACCEPT_STRING: String = "ACCEPT
            MISSION"
const CLOSE_STRING: String = "CLOSE
            COMMS"

enum STATE { PENDING, ERROR, ACCEPTED }
var current_state: int = STATE.PENDING

func _ready() -> void:
	SignalBus.update_comms_popup.connect(setup)
	SignalBus.close_comms_popup.connect(_close)

# Called immediately by the HUD upon instantiating, and by SignalBus for updates
func setup(message: String, new_state: int) -> void:
	comms_message.text = message
	current_state = new_state
	
	if current_state == STATE.PENDING:
		interact_button.text = ACCEPT_STRING
		interact_button.pressed = false # Reset visual toggle if necessary
	else:
		interact_button.text = CLOSE_STRING

# Connect these to your UI button pressed signals
func _on_interact_pressed() -> void:
	AudioManager.play_UI_click_sound()
	if current_state == STATE.PENDING:
		SignalBus.comms_action_taken.emit("interact")
	else:
		SignalBus.comms_action_taken.emit("close")

func _on_reroll_pressed() -> void:
	AudioManager.play_UI_click_sound()
	if current_state == STATE.PENDING:
		SignalBus.comms_action_taken.emit("reroll")

func _close() -> void:
	queue_free()
