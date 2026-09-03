@tool
extends Node

const SAVE_DIRECTORY: String = "res://assets/data/ship_data/"

var SHIP_DATA: Dictionary  # Loaded from ShipData.txt

@export_category("Resource Generation")
@export var gen_ship_rss: bool = false:
	set(value):
		if value:
			_generate_resources()
		gen_ship_rss = false

# Load ship resources into SHIP_DATA array
func _init() -> void:
	_load_txt("res://assets/data/ShipData.txt", SHIP_DATA)


func _generate_resources() -> void:
	print("Starting ship base resource generation...")
	_clear_directory(SAVE_DIRECTORY)
	
	var generated_count: int = 0
	
	for key in Utility.SHIP_TYPES:
		var ship_enum: int = Utility.SHIP_TYPES[key]
		
		# Failsafe in case your enum has a ship not yet added to the dictionary
		if not SHIP_DATA.has(ship_enum):
			continue
			
		var base_data: Dictionary = SHIP_DATA[ship_enum]
		var stats: BaseShipInfo = BaseShipInfo.new()
		
		var x = base_data.get("SPRITE_X", 999.0)
		var y = base_data.get("SPRITE_Y", 999.0)
		stats.sprite_coords = Vector2(x, y)
		stats.collision_polygon = base_data.get("COLLISION_POLY", [])
		
		var x2 = base_data.get("SHIELD_SCALE_X", 0.0)
		var y2 = base_data.get("SHIELD_SCALE_Y", 0.0)
		stats.shield_scale = Vector2(x2, y2)
		
		stats.muzzle_pos = base_data.get("MUZZLE_POS", 0)
		#stats.cargo_capacity = base_data.get("CARGO_SIZE", 1)
		#stats.reputation_value = 100
		
		stats.ship_type  = base_data.get("INDEX", Utility.SHIP_TYPES.La_Sirena)
		stats.faction    = base_data.get("FACTION", Utility.FACTION.NEUTRAL)
		stats.archetype  = base_data.get("ARCHETYPE", Scaling.ARCHETYPE.NONE)
		stats.trait_type = base_data.get("TRAIT", Scaling.SHIP_TRAIT.NONE)
		
		# Set the BASE values. 
		stats.damage_mult = 1.0
		stats.base_HP      = base_data.get("MAX_HP", 100.0)
		stats.base_shield  = base_data.get("MAX_SHIELD", 50.0)
		stats.base_speed   = base_data.get("SPEED", 750.0)
		stats.base_agility = base_data.get("AGILITY", 150.0)
		stats.warp_range  = 1
		stats.base_energy  = 150.0
		
		var file_name: String = _get_formatted_file_name(key) + ".tres"
		var save_path: String = SAVE_DIRECTORY + file_name
		
		var error: Error = ResourceSaver.save(stats, save_path)
		if error == OK:
			generated_count += 1
		else:
			push_error("Failed to save resource at: ", save_path)
			
	print("Ship resource generation complete! Generated ", generated_count, " base resources.")

func _clear_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				dir.remove(file_name)
			file_name = dir.get_next()
	else:
		DirAccess.make_dir_recursive_absolute(path)

func _get_formatted_file_name(raw_name: String) -> String:
	var parts = raw_name.split("_")
	var formatted_parts: PackedStringArray = []
	for part in parts:
		if part.length() > 0:
			var capitalized = part.substr(0, 1).to_upper() + part.substr(1).to_lower()
			formatted_parts.append(capitalized)
	return "_".join(formatted_parts)


func _load_txt(path: String, target: Dictionary) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var file: FileAccess = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		push_error("TXT loading failed at %s — error: %s" % [path, FileAccess.get_open_error()])
		file = FileAccess.open(path, FileAccess.READ)
		return

	var headers: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < headers.size() or (row.size() == 1 and row[0] == ""):
			continue

		var entry: Dictionary = {}
		for i: int in range(headers.size()):
			var header: String = headers[i]
			var raw: Variant = _parse_csv_value(row[i])
			entry[header] = _convert_special_value(header, raw)

		var key: Variant = entry.get("INDEX")
		if key != null:
			target[key] = entry


func _convert_special_value(header: String, value: Variant) -> Variant:
	if value == null:
		return value
	if value is String and value == "":
		return value
	match header:
		"ARCHETYPE":
			return _parse_enum(Scaling.ARCHETYPE, str(value), Scaling.ARCHETYPE.CRUISER)
		"TRAIT":
			return _parse_enum(Scaling.SHIP_TRAIT, str(value), Scaling.SHIP_TRAIT.NONE)
		"FACTION":
			return _parse_enum(Utility.FACTION, str(value), Utility.FACTION.NEUTRAL)
		_:
			return value


func _parse_enum(enum_dict: Dictionary, value: String, fallback: int) -> int:
	var key: String = value.strip_edges().to_upper()
	if enum_dict.has(key):
		return enum_dict[key]
	push_warning("CSV enum parse failed — key '%s' not found, using fallback" % value)
	return fallback


func _parse_csv_value(value: String) -> Variant:
	# Empty string
	if value == "":
		return null
	# Bool
	if value.to_lower() == "true":  return true
	if value.to_lower() == "false": return false
	# Integer
	if value.is_valid_int():        return value.to_int()
	# Float
	if value.is_valid_float():      return value.to_float()
	# Fallback to string
	return value
