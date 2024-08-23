extends ParallaxBackground

@export var scrolling_speed = 8


func _process(delta):
	scroll_offset.x -= scrolling_speed*delta
