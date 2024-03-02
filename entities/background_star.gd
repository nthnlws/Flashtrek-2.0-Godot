class_name BackgroundStar2D

extends Polygon2D

const X_LIMIT: float = 976.00
const Y_LIMIT: float = 528.00

var move_factor: float = 1


func _init() -> void:
	randomize()
	move_factor = rand_range(0.5, 1.0)
	draw_star()
	scale = move_factor * Vector2(0.05, 0.05)
	modulate.a = move_factor * move_factor
	z_index = -1


func draw_star() -> void:
	var points = []
	var vertex: int = 16
	points.resize(vertex)
	for v in vertex:
		var angle = (PI * 2 / vertex) * v
		var dist = 64.0
		points[v] = Vector2(sin(angle) * dist, cos(angle) * dist)
	
	set_polygon(points)


func update_position(delta: Vector2 = Vector2.ZERO) -> void:
	# check the star is within a bounding box. if it isnt, flip it
	if abs(position.x) > X_LIMIT:
		position.x = X_LIMIT * sign(position.x) * -1
	if abs(position.y) > Y_LIMIT:
		position.y = Y_LIMIT * sign(position.y) * -1
	
	position += delta * move_factor
