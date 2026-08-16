@tool
extends Node2D

@export_category("Actions")
## Click this checkbox in the inspector to generate a new random pile.
@export var regenerate: bool = false :
	set(value):
		if value:
			generate_pile()
		regenerate = false

@export_category("Save / Load")
## Click to save the currently generated pile as a reusable resource.
@export var save_current_pile: bool = false :
	set(value):
		if value:
			_save_pile_to_resource()
		save_current_pile = false

## Drag a saved ScrapPileConfig here to load it.
@export var saved_pile_config: ScrapPileConfig
## Click to load the assigned ScrapPileConfig above.
@export var load_pile: bool = false :
	set(value):
		if value:
			_load_pile_from_resource()
		load_pile = false

@export_category("Pile Settings")
## The maximum radius distance a scrap piece can spawn from the center.
@export var spread_radius: float = 80.0
## Minimum distance between each piece of scrap.
@export var piece_spacing: float = 24.0 
@export var poisson_retries: int = 30

@export_category("Piece Counts")
@export var min_small_pieces: int = 4
@export var max_small_pieces: int = 8
@export var min_medium_pieces: int = 1
@export var max_medium_pieces: int = 3
## 0.0 is 0% chance, 1.0 is 100% chance.
@export_range(0.0, 1.0) var large_piece_chance: float = 0.25

var scrap_data: ScrapSpriteSheet = ScrapSpriteSheet.new()
var scrap_texture: Texture2D = preload("uid://bmybeo1pjo21w")

func generate_pile() -> void:
	if not scrap_data or not scrap_texture:
		push_warning("ScrapPileGenerator: Missing scrap_data resource or texture!")
		return

	_clear_existing_pile()

	# Determine how many of each piece we want
	var num_small = randi_range(min_small_pieces, max_small_pieces)
	var num_medium = randi_range(min_medium_pieces, max_medium_pieces)
	var spawn_large = randf() <= large_piece_chance and scrap_data.large_scraps.size() > 0

	# 1. Generate all possible positions using Poisson Disc Sampling
	var points: PackedVector2Array = PoissonDiscSampling.generate_points_for_circle(
		Vector2.ZERO, 
		spread_radius, 
		piece_spacing, 
		poisson_retries
	)
	
	# 2. Shuffle the points so we don't always populate from the same origin pattern
	var point_array = Array(points)
	point_array.shuffle()
	
	var current_point_index: int = 0
	
	# 3. Spawn Large Piece
	if spawn_large and current_point_index < point_array.size():
		_spawn_piece(scrap_data.large_scraps.pick_random(), point_array[current_point_index])
		current_point_index += 1

	# 4. Spawn Medium Pieces
	for i in range(num_medium):
		if current_point_index >= point_array.size():
			break 
		if scrap_data.medium_scraps.size() > 0:
			_spawn_piece(scrap_data.medium_scraps.pick_random(), point_array[current_point_index])
			current_point_index += 1

	# 5. Spawn Small Pieces
	for i in range(num_small):
		if current_point_index >= point_array.size():
			break
		if scrap_data.small_scraps.size() > 0:
			_spawn_piece(scrap_data.small_scraps.pick_random(), point_array[current_point_index])
			current_point_index += 1

func _spawn_piece(region_v4: Vector4, spawn_pos: Vector2) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = scrap_texture
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region_v4.x, region_v4.y, region_v4.z, region_v4.w)
	
	sprite.position = spawn_pos
	sprite.rotation = randf() * TAU
	
	add_child(sprite)
	
	_set_owner(sprite)

func _clear_existing_pile() -> void:
	for child in get_children():
		remove_child(child)
		child.free()

func _set_owner(node: Node) -> void:
	if Engine.is_editor_hint():
		if get_tree() and get_tree().edited_scene_root:
			node.owner = get_tree().edited_scene_root
	else:
		node.owner = self

# --- SAVE / LOAD LOGIC ---

func _save_pile_to_resource() -> void:
	if get_child_count() == 0:
		push_warning("Pile is empty. Generate a pile before saving.")
		return
		
	var config = ScrapPileConfig.new()
	
	# Extract data from current sprites
	for child in get_children():
		if child is Sprite2D and child.region_enabled:
			config.positions.append(child.position)
			config.rotations.append(child.rotation)
			config.regions.append(child.region_rect)
			
	# Ensure directory exists
	var dir_path = "res://resources/scrap_piles/"
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		
	# Format filename: scrap_pile_YYYY-MM-DD_HH-MM-SS.tres
	var time_str = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var file_path = dir_path + "scrap_pile_" + time_str + ".tres"
	
	var error = ResourceSaver.save(config, file_path)
	
	if error == OK:
		print("Successfully saved Scrap Pile configuration to: ", file_path)
	else:
		push_error("Failed to save Scrap Pile configuration! Error code: ", error)

func _load_pile_from_resource() -> void:
	if not saved_pile_config:
		push_warning("Assign a ScrapPileConfig in the Inspector before clicking Load Pile.")
		return
		
	_clear_existing_pile()
	
	for i in range(saved_pile_config.positions.size()):
		var sprite = Sprite2D.new()
		sprite.texture = scrap_texture
		sprite.region_enabled = true
		sprite.region_rect = saved_pile_config.regions[i]
		sprite.position = saved_pile_config.positions[i]
		sprite.rotation = saved_pile_config.rotations[i]
		
		add_child(sprite)
		_set_owner(sprite)
		
	print("Successfully loaded Scrap Pile!")
