class_name Background2D

extends Node

const HALF_X: float = 960.00
const HALF_Y: float = 540.00

const MAX_X: float = 1920.00
const MAX_Y: float = 1080.00

func _init(type: int = 5) -> void:
	randomize()
	var number_of_stars = randi() % 50 + 50
	var star_positions: PoolVector2Array = []
	# this is temporary as the constructor only needs to exist for the tests.
	if type == 5:
		type = randi() % 3
	
	match type:
		1:
			star_positions = _grid_scatter(number_of_stars)
		2:
			star_positions = _halton_scatter(number_of_stars)
		_:
			star_positions = _random_scatter(number_of_stars)
	_add_stars(star_positions)



func update_star_positions(delta: Vector2 = Vector2.ZERO) -> void:
	for child in get_children():
		child.update_position(delta)

# pure random scatter
func _random_scatter(n: int) -> PoolVector2Array:
	var positions = []
	positions.resize(n)
	for i in n:
		var x_factor = rand_range(-1.0, 1.0)
		var y_factor = rand_range(-1.0, 1.0)
		var vect = Vector2(HALF_X * x_factor, HALF_Y * y_factor)
		positions[i] = vect
	return positions

# scatters the stars across a grid... it is grim but it is there for reference
func _grid_scatter(n: int) -> PoolVector2Array:
	var positions = []
	# get the number of points to make an approximate rectangle of area "n"
	var height:int  = int(sqrt(n))
	var width: int = height + 2
	positions.resize(width * height)
	# As the background will be drawn on the screen, will need to offset the positions up and to the left.
	var index: int = 0
	for h in range(height):
		for w in range(width):
			# apply slight randomisation to the grid of points.
			var offset: float = rand_range(1, 1.05)
			var pos: Vector2 = Vector2(w * MAX_X/width, h * MAX_Y/height) * offset
			# offset the position
			pos -= Vector2(HALF_X, HALF_Y) * offset
			positions[index] = pos
			index += 1
	
	return positions

# while searching through google for ways of scattering points on a grid I came across the Halton Sequence... https://en.wikipedia.org/wiki/Halton_sequence.
# It makes quite a nice evenly covered background...
func _halton_scatter(n: int) -> PoolVector2Array:
	var positions: PoolVector2Array = []
	positions.resize(n)
	# through testing pairs (2,3) and (5,7) give nice even coverage with no distinct alignments. (3,5) produces lots of straight lines.
	var prime_a: PoolIntArray = [2, 5]
	var prime_b: PoolIntArray = [3, 7]
	
	var index = randi() % prime_a.size()
	
	var a: int = prime_a[index]
	var b: int = prime_b[index]
	
	for stars in range(n):
		var pos: Vector2 = Vector2(_halton(stars, a) * MAX_X, _halton(stars, b) * MAX_Y)
		positions[stars] = pos - Vector2(HALF_X, HALF_Y)
	
	return positions


# translated from C++ code found here: https://stackoverflow.com/questions/42661304/implementing-4-dimensional-halton-sequence. after reading for a while, still dont get what the hell it does but is needed for the above. Sometimes you have got just close your eyes and trust stack overflow...
func _halton(index: int, base: int) -> float:
	var result: float = 0
	var f: float = 1
	
	while (index > 0):
		f = f / base
		result = result + f * (index % base)
		index = index / base
	return result

# function name says it all realyl...
func _add_stars(positions: PoolVector2Array) -> void:
	for pos in positions:
		var star = BackgroundStar2D.new()
		star.set_position(pos)
		add_child(star)
