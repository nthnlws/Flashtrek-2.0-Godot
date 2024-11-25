extends Node2D

var ships = Utility.ship_sprites
var current_ship

var counter:int = 0:
	set(value):
		counter = clamp(value, 0, 91)




func _ready():
	var coords = mod_to_region(51)
	counter = 51
	print(coords)
	self.texture.region = coords
	current_ship = ships.values()[0]
	
func _process(delta):
	if Input.is_action_just_pressed("rotate_left"):
		counter -=1
		current_ship = ships.values()[counter]
		#print(ships.keys()[counter])
		self.texture.region = current_ship
		print(counter)
	if Input.is_action_just_pressed("rotate_right"):
		counter +=1
		current_ship = ships.values()[counter]
		print(ships.keys()[counter])
		self.texture.region = current_ship
		print(counter)

func mod_to_region(index: int) -> Rect2:
	# Ensure the index is within the valid range
	if index < 0 or index > 91:
		push_error("Index out of bounds. Must be between 0 and 91.")
		return Rect2(Vector2.ZERO, Vector2(48, 48))
	
	# Calculate row and column
	var row = index / 9  # Integer division to find the row
	var col = index % 9  # Modulus to find the column

	# Calculate pixel coordinates
	var coords = Vector2(col * 48, row * 48)

	# Return the Rect2 with the region and size 48x48
	return Rect2(coords, Vector2(48, 48))
