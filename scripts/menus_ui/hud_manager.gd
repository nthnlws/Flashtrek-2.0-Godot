extends Control
class_name HUDmanager

@export var comms_ui_scene: PackedScene
var active_comms_popup: CommsUI = null

func _ready() -> void:
	SignalBus.request_comms_popup.connect(_on_request_comms_popup)

func _on_request_comms_popup(message: String, state: int) -> void:
	# Strict safeguard: Destroy any existing popup before creating a new one
	if is_instance_valid(active_comms_popup):
		active_comms_popup.queue_free()
		
	active_comms_popup = comms_ui_scene.instantiate()
	add_child(active_comms_popup)
	active_comms_popup.setup(message, state)
