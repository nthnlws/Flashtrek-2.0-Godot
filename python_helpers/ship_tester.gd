extends Control

#@onready var coll_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var sprite: Sprite2D = $Sprite
@onready var area: Area2D = $Area2D
@onready var coll: CollisionPolygon2D = %CollisionPolygon2D
@onready var sprite_animation: AnimationPlayer = $Sprite/SpriteAnimation


var sprite_areas: Array[Rect2] = [
	Rect2(0, 0, 48, 48),
	Rect2(48, 0, 48, 48),
	Rect2(96, 0, 48, 48),
	Rect2(144, 0, 48, 48),
	Rect2(192, 0, 48, 48),
	Rect2(240, 0, 48, 48),
	Rect2(288, 0, 48, 48),
	Rect2(336, 0, 48, 48),
	Rect2(384, 0, 48, 48),
	Rect2(432, 0, 48, 48),
	Rect2(480, 0, 48, 48),
	Rect2(528, 0, 48, 48),
	Rect2(576, 0, 48, 48),
	Rect2(624, 0, 48, 48),
	Rect2(0, 48, 48, 48),
	Rect2(48, 48, 48, 48),
	Rect2(96, 48, 48, 48),
	Rect2(144, 48, 48, 48),
	Rect2(192, 48, 48, 48),
	Rect2(240, 48, 48, 48),
	Rect2(288, 48, 48, 48),
	Rect2(336, 48, 48, 48),
	Rect2(384, 48, 48, 48),
	Rect2(432, 48, 48, 48),
	Rect2(480, 48, 48, 48),
	Rect2(528, 48, 48, 48),
	Rect2(576, 48, 48, 48),
	Rect2(624, 48, 48, 48),
	Rect2(0, 96, 48, 48),
	Rect2(48, 96, 48, 48),
	Rect2(96, 96, 48, 48),
	Rect2(144, 96, 48, 48),
	Rect2(192, 96, 48, 48),
	Rect2(288, 96, 48, 48),
	Rect2(336, 96, 48, 48),
	Rect2(384, 96, 48, 48),
	Rect2(432, 96, 48, 48),
	Rect2(480, 96, 48, 48),
	Rect2(528, 96, 48, 48),
	Rect2(576, 96, 48, 48),
	Rect2(624, 96, 48, 48),
	Rect2(0, 144, 48, 48),
	Rect2(48, 144, 48, 96),
	Rect2(96, 144, 48, 48),
	Rect2(144, 144, 48, 48),
	Rect2(192, 144, 48, 48),
	Rect2(240, 144, 48, 48),
	Rect2(288, 144, 48, 48),
	Rect2(336, 144, 48, 48),
	Rect2(384, 144, 48, 48),
	Rect2(432, 144, 48, 48),
	Rect2(480, 144, 48, 48),
	Rect2(528, 144, 48, 48),
	Rect2(576, 144, 48, 48),
	Rect2(624, 144, 48, 48),
	Rect2(0, 192, 48, 48),
	Rect2(96, 192, 48, 48),
	Rect2(144, 192, 48, 48),
	Rect2(192, 192, 48, 48),
	Rect2(240, 192, 48, 48),
	Rect2(288, 192, 48, 48),
	Rect2(336, 192, 48, 48),
	Rect2(384, 192, 48, 48),
	Rect2(432, 192, 48, 48),
	Rect2(480, 192, 48, 48),
	Rect2(528, 192, 48, 48),
	Rect2(576, 192, 48, 48),
	Rect2(624, 192, 48, 48),
	Rect2(0, 240, 48, 48),
	Rect2(48, 240, 48, 96),
	Rect2(96, 240, 48, 48),
	Rect2(144, 240, 48, 48),
	Rect2(192, 240, 48, 48),
	Rect2(240, 240, 48, 48),
	Rect2(288, 240, 48, 48),
	Rect2(336, 240, 48, 48),
	Rect2(384, 240, 48, 48),
	Rect2(432, 240, 48, 48),
	Rect2(480, 240, 48, 48),
	Rect2(528, 240, 48, 48),
	Rect2(576, 240, 48, 48),
	Rect2(624, 240, 48, 48),
	Rect2(0, 288, 48, 48),
	Rect2(96, 288, 48, 48),
	Rect2(144, 288, 48, 48),
	Rect2(192, 288, 48, 48),
	Rect2(240, 288, 48, 48),
	Rect2(288, 288, 48, 48),
	Rect2(336, 288, 48, 48),
	Rect2(384, 288, 48, 48),
	Rect2(432, 288, 48, 48),
	Rect2(480, 288, 48, 48),
	Rect2(528, 288, 48, 48),
	Rect2(576, 288, 48, 48),
	Rect2(624, 288, 48, 48)
]

var collision_array: Array[PackedVector2Array] = []


func _process(delta: float) -> void:
	if sprite.material:
		update_shader_region()


func update_shader_region() -> void:
	var tex = sprite.texture
	if tex is AtlasTexture:
		var atlas_size = tex.atlas.get_size()   # Full spritesheet size (336, 672)
		var region     = tex.region             # pixel offset within the sheet
		var uv_min = Vector2(region.position.x / atlas_size.x,
							 region.position.y / atlas_size.y)

		sprite.material.set_shader_parameter("region_uv_min", uv_min)
	else:
		# uv_min stays (0, 0) when not AtlasTexture
		sprite.material.set_shader_parameter("region_uv_min", Vector2.ZERO)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug1"):
		sprite_animation.play("cloak_ROMULAN")
		return
	elif event.is_action_pressed("debug2"):
		sprite_animation.play("uncloak_ROMULAN")
		return

func _ready() -> void:
	var poly: PackedVector2Array = sprite_to_polygon()
	collision_array.append(poly)
	save_collision_array_to_txt("C:/Users/nthnl/Desktop/collision_data.txt")

func sprite_to_polygon() -> PackedVector2Array:
	# Clear previous children
	for child in area.get_children():
		child.queue_free()
		area.remove_child(child)

	var image: Image = sprite.texture.get_image()
	if image == null:
		push_warning("sprite_to_polygon: no image found for region %s" % sprite.texture.region)
		return PackedVector2Array()

	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image)

	var polys: Array = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, sprite.texture.get_size()))
	if polys.is_empty():
		push_warning("sprite_to_polygon: no opaque polygons found for region %s" % sprite.texture.region)
		return PackedVector2Array()

	var offset: Vector2 = Vector2.ZERO
	if sprite.centered:
		offset = -Vector2(image.get_size()) / 2.0

	# Use the largest polygon as the primary collision shape
	var largest: PackedVector2Array = PackedVector2Array()
	for poly: PackedVector2Array in polys:
		var collision_polygon := CollisionPolygon2D.new()
		collision_polygon.polygon = poly
		collision_polygon.position = offset
		area.add_child(collision_polygon)
		if poly.size() > largest.size():
			largest = poly

	# Return largest shifted by offset for saving
	var result := PackedVector2Array()
	for point: Vector2 in largest:
		result.append(point + offset)
	return result
	

func save_collision_array_to_txt(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		for poly in collision_array:
			var line := []
			for point in poly:
				line.append(str(point))  # Format: "x, y"
			file.store_line(" ".join(line))  # Store full polygon on one line
		file.close()
		print("Collision data saved to %s" % path)
	else:
		print("Failed to open file for writing: %s" % path)
