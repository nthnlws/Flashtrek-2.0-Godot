extends TextureRect

@export var shield_node: ColorRect
@export var fill_color: Color = Color(0.0, 1.0, 0.0, 1.0)
@export var max_HP: float = 100.0:
	set(value):
		max_HP = value
		update_hud_health_display()
var current_HP: float = 100.0:
	set(value):
		current_HP = clampf(value, 0.0, max_HP)
		update_hud_health_display()
		calculate_and_set_content_bounds()

# Match the enum in the shader
enum FillDirection { HORIZONTAL_LEFT_RIGHT, HORIZONTAL_RIGHT_LEFT, VERTICAL_TOP_DOWN, VERTICAL_BOTTOM_UP }
@export var health_fill_direction: FillDirection = FillDirection.HORIZONTAL_LEFT_RIGHT
var _content_bounds_in_region_uv: Rect2 = Rect2(0, 0, 1, 1) # x, y, width, height (normalized)


func _ready():
	current_HP = max_HP
	initialize_hull_icon()


func update_hud_health_display() -> void:
	if material is ShaderMaterial:
		var mat: ShaderMaterial = material
		var health_ratio = 0.0
		if max_HP > 0:
			health_ratio = current_HP / max_HP
		mat.set_shader_parameter("health_ratio", health_ratio)


func update_sprite_position() -> void:
	var current_scale:Vector2 = shield_node.scale
	var new_sprite_x:float = (shield_node.custom_minimum_size.x * current_scale.x / 2) + 24
	var new_sprite_y:float = (shield_node.custom_minimum_size.y * current_scale.y / 2) - 24
	position = Vector2(new_sprite_x, new_sprite_y)
	
	
func initialize_hull_icon():
	if material is ShaderMaterial:
		var mat: ShaderMaterial = material
		var atlas_tex = texture as AtlasTexture
		var base_texture = atlas_tex.atlas
		var region = atlas_tex.region
		
		mat.set_shader_parameter("fill_direction", health_fill_direction)
		mat.set_shader_parameter("health_color", fill_color)
		
		var base_tex_size = base_texture.get_size()
		var region_uv_offset = Vector2(region.position.x / base_tex_size.x, region.position.y / base_tex_size.y)
		var region_uv_size = Vector2(region.size.x / base_tex_size.x, region.size.y / base_tex_size.y)

		mat.set_shader_parameter("region_uv_offset", region_uv_offset)
		mat.set_shader_parameter("region_uv_size", region_uv_size)
		
		# You can also set other uniforms here if they need to change dynamically
		# e.g., mat.set_shader_parameter("health_color", Color.RED if health_ratio < 0.25 else Color.GREEN)
		# mat.set_shader_parameter("outline_width", 2.0)
	elif material == null:
		printerr("Health display node has no material assigned!")

func calculate_and_set_content_bounds():
	var atlas_tex = texture as AtlasTexture
	if not atlas_tex: # Not an atlas texture, assume content is full
		_content_bounds_in_region_uv = Rect2(0, 0, 1, 1) # Default to full
		(material as ShaderMaterial).set_shader_parameter("content_bounds_in_region_uv_pos", _content_bounds_in_region_uv.position)
		(material as ShaderMaterial).set_shader_parameter("content_bounds_in_region_uv_size", _content_bounds_in_region_uv.size)
		return

	var base_atlas_image: Image = atlas_tex.atlas.get_image()
	var region_rect_px: Rect2i = atlas_tex.region

	if base_atlas_image == null or base_atlas_image.is_empty():
		printerr("Base atlas image is null or empty for content bounds calculation.")
		_content_bounds_in_region_uv = Rect2(0, 0, 1, 1) # Fallback
	elif region_rect_px.size.x <= 0 or region_rect_px.size.y <= 0:
		# print("Region size is zero or negative, cannot calculate content bounds.")
		_content_bounds_in_region_uv = Rect2(0, 0, 0, 0) # No content if region is empty
	else:
		var min_x_in_region = region_rect_px.size.x # Initialize min to max possible value
		var min_y_in_region = region_rect_px.size.y # Initialize min to max possible value
		var max_x_in_region = -1 # Initialize max to less than min possible value
		var max_y_in_region = -1 # Initialize max to less than min possible value
		var found_pixel = false

		for y_offset in range(region_rect_px.size.y):
			for x_offset in range(region_rect_px.size.x):
				var absolute_x = region_rect_px.position.x + x_offset
				var absolute_y = region_rect_px.position.y + y_offset

				# Boundary check against the full base image
				if absolute_x < 0 or absolute_x >= base_atlas_image.get_width() or \
				   absolute_y < 0 or absolute_y >= base_atlas_image.get_height():
					continue # Should not happen if region is valid within atlas

				var pixel_alpha = base_atlas_image.get_pixel(absolute_x, absolute_y).a
				if pixel_alpha > 0.01: # Alpha threshold (0.01 is very low, 0.1 was used before)
					min_x_in_region = min(min_x_in_region, x_offset)
					min_y_in_region = min(min_y_in_region, y_offset)
					max_x_in_region = max(max_x_in_region, x_offset)
					max_y_in_region = max(max_y_in_region, y_offset)
					found_pixel = true
		
		if not found_pixel:
			_content_bounds_in_region_uv = Rect2(0, 0, 0, 0)
		else:
			# Calculate normalized position and size relative to the region
			var content_pos_x_norm = float(min_x_in_region) / region_rect_px.size.x
			var content_pos_y_norm = float(min_y_in_region) / region_rect_px.size.y
			# For size, it's (max - min + 1) because max is inclusive
			var content_size_x_norm = float(max_x_in_region - min_x_in_region + 1) / region_rect_px.size.x
			var content_size_y_norm = float(max_y_in_region - min_y_in_region + 1) / region_rect_px.size.y
			
			_content_bounds_in_region_uv = Rect2(content_pos_x_norm, content_pos_y_norm, content_size_x_norm, content_size_y_norm)

	#print("Final Calculated content bounds (normalized within region): ", _content_bounds_in_region_uv) # Debug
	(material as ShaderMaterial).set_shader_parameter("content_bounds_in_region_uv_pos", _content_bounds_in_region_uv.position)
	(material as ShaderMaterial).set_shader_parameter("content_bounds_in_region_uv_size", _content_bounds_in_region_uv.size)
	
	
# Debug func for shader testing
#func _input(event): 
	#if Input.is_action_just_pressed("rotate_left"):
		#self.current_health -= 10
		#print("HUD Health: ", current_HP)
	#if Input.is_action_just_pressed("rotate_right"):
		#self.current_health += 10
		#print("HUD Health: ", current_HP)
