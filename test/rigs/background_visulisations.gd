extends Camera2D

var num:int = 0


func _ready() -> void:
	_change_background()


func _change_background() -> void:
	for child in $Background.get_children():
		child.queue_free()
	
	var bg = Background2D.new(num)
	$Background.add_child(bg)
	num += 1
	num %= 3


func _on_Spawn_timeout() -> void:
	_change_background()
