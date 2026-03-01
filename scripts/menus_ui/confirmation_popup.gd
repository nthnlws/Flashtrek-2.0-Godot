extends Control

signal confirm_save_delete
signal abort_save_delete

@onready var slot_value: Label = $Panel/VBoxContainer/SlotValue

const hidden_position:Vector2 = Vector2(244, 467)
const shown_position:Vector2 = Vector2(244, 367)
const animation_duration:float = 0.45

var selected_node:String
var showing:bool = false

func _ready() -> void:
	size.y = 0

func _on_confirm_clicked() -> void:
	confirm_save_delete.emit(selected_node)
	match selected_node:
		"Slot1":
			SaveManager.delete_save(1)
		"Slot2":
			SaveManager.delete_save(2)
		"Slot3":
			SaveManager.delete_save(3)
		_: printerr('No slot match found for deletion for node: %s' % selected_node)
	close_popup()

func _on_abort_clicked() -> void:
	abort_save_delete.emit()
	close_popup()

func open_popup(node_name:String) -> void:
	selected_node = node_name
	showing = true
	
	# Set popup text
	var slot_num:int
	match node_name:
		"Slot1":
			slot_num = 1
		"Slot2":
			slot_num = 2
		"Slot3":
			slot_num = 3
	slot_value.text = "  >  Save Slot %s" % slot_num
	
	var tween:Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "size", Vector2(247, 96), animation_duration)


func close_popup() -> void:
	showing = false
	var tween:Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "size", Vector2(247, 0), animation_duration)
	await tween.finished
	selected_node = ""
