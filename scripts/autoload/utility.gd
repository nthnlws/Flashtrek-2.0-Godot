extends Node
class_name game_data

var player_name: String = "USS Enterprise"

enum FACTION { FEDERATION, KLINGON, ROMULAN, NEUTRAL }

# Used for global references to dict ship data JSON
enum SHIP_TYPES {
	Merchantman,
	Keldon_Class,
	batlh_Class,
	JemHadar,
	sech_Class,
	Pathfinder_Class,
	Steamrunner_Class,
	Soyuz_Class,
	Miranda_Class,
	Nimitz_Class,
	Freedom_Class,
	Intrepid_Class,
	Niagara_Class,
	Talarian_Freighter,
	Galor_Class,
	Bajoran_Freighter,
	daSpu_Class,
	Klingon_Bird_of_Prey,
	Walker_Class,
	Sovereign_Class,
	Malachowski_Class,
	Miranda_Class_Lantree_variant,
	Nova_Class,
	Constitution_Class_Strange_New_Worlds,
	Nova_Class_Rhode_Island_variant,
	New_Orleans_Class,
	DKora_Marauder,
	Hideki_Class,
	Qugh_Class,
	Hiawatha_Class,
	Mars_Synth_Defense_Ship,
	Intrepid_Class_Aeroshuttle,
	Gagarin_Class,
	Saber_Class,
	Miranda_Class_Saratoga_variant,
	Parliament_Class,
	Georgiou_Class,
	Defiant_Class,
	Cheyenne_Class,
	Peregrine_Class,
	Odyssey_Class,
	D5_Class,
	Risian_Corvette,
	Breen_Interceptor,
	Bajoran_Interceptor,
	Oberth_Class,
	Cardenas_Class,
	Vesta_Class,
	Miranda_Class_Antares_variant,
	Challenger_Class,
	Constitution_II_Class,
	Constitution_III_Class,
	Galaxy_Class,
	Maquis_Raider,
	chargh_Class,
	Wallenberg_Class,
	Dhailkhina_Class,
	Sampson_Class,
	Excelsior_Class,
	Class_III_Neutronic_Fuel_Carrier_Kobayashi_Maru,
	Shepard_Class,
	Norway_Class,
	California_Class,
	Galaxy_Class_Venture_variant,
	Springfield_Class,
	Theta_Class,
	Groumall_Freighter,
	Tellarite_Cruiser,
	Magee_Class,
	bortaS_bIr_Class,
	Dia_Vectau_Class,
	Hernandez_Class,
	Excelsior_Class_Refit,
	Luna_Class,
	Edison_Class,
	Constellation_Class,
	Sagan_Class,
	Sutherland_Class,
	Nebula_Class_Phoenix_variant,
	La_Sirena,
	Monaveen,
	Risian_Luxury_Cruiser,
	Brel_Class,
	Dderidex_Class,
	Engle_Class,
	Reliant_Class,
	Ross_Class,
	Akira_Class,
	Ambassador_Class,
	Excelsior_II_Class,
	Hoover_Class,
	Nebula_Class,
}

#Accessed by Utility.SHIP_DATA.values()[Utility.SHIP_TYPES.ship_name]
var SHIP_DATA: Dictionary # Loaded from ShipData.JSON file
var PLAYER_SHIP_STATS: Dictionary # Loaded from ShipData.JSON file
var ENEMY_SHIP_STATS: Dictionary # Loaded from ShipData.JSON file

var is_initial_load: bool = true
var mainScene:Node = null # Set by main scene on _init()
var fadeLength: float = 2.0 # Used for fade in/out on Galaxy Warp

# Colors
const UI_yellow: String = "[color=#FFCC66]"
const UI_blue: String = "[color=#6699CC]"
const UI_cargo_green: String = "[color=#1DCC4B]"
const UI_ship_lime: String = "[color=#3bdb8b]"
const damage_red: String = "[center][color=#eb4034]"
const damage_green: String = "[center][color=#46e065]"
const damage_blue: String = "[color=#80b9ff]"
const fed_blue: String = "[color=#3984BE]"
const rom_green: String = "[color=#009301]"
const klin_red: String = "[color=#FF2A2A]"
const neut_cyan: String = "[color=#78D9C2]"

const DAMAGE_MARKER = preload("res://scenes/level_entities/damage_marker.tscn")

func _init() -> void:
	load_JSON_ship_data()
	
func _ready() -> void:
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()
	
	
func _input(event: InputEvent) -> void:
	#Fullscreen management
	if Input.is_action_just_pressed("f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# Click button sound variables
var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0
const HIGH:float = 2.0
const LOW:float = 0.5
func play_click_sound(volume: float) -> void: 
	var sound_array_length: int = sound_array.size() - 1

	match sound_array_location:
		sound_array_length: # When location in array = array size, shuffle array and reset location
			var default_db: float = sound_array[sound_array_location].volume_db
			var effective_volume: float = default_db + volume
			sound_array[sound_array_location].set_volume_db(effective_volume)
			sound_array[sound_array_location].stop() # Ensure the sound is stopped before playing
			sound_array[sound_array_location].play()
			sound_array[sound_array_location].set_volume_db(default_db)
			sound_array.shuffle()
			sound_array_location = 0
		_: # Runs for all array values besides last
			var default_db: float = sound_array[sound_array_location].volume_db
			var effective_volume: float = default_db + volume
			sound_array[sound_array_location].set_volume_db(effective_volume)
			sound_array[sound_array_location].stop() # Ensure the sound is stopped before playing
			sound_array[sound_array_location].play()
			sound_array[sound_array_location].set_volume_db(default_db)
			sound_array_location += 1

func store_level_data(save_data: Dictionary) -> void:
	var file_path: String = "user://level_data.json"
	
	# Save to file
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t", false))
	file.close()

#func load_level_data()
# Check if the file exists and load existing data if it does
	#if FileAccess.file_exists(file_path):
		#var file = FileAccess.open(file_path, FileAccess.READ)
		#save_data = JSON.parse_string(file.get_as_text())
		#file.close()

func createDamageIndicator(damage: float, color: String, position: Vector2) -> void:
	damage = snapped(damage, 0.1)
	var string: String = "[center]" + color + str(damage)
	var label: Marker2D = DAMAGE_MARKER.instantiate()
	add_child(label)
	label.global_position = position
	var text: RichTextLabel = label.get_child(0)
	text.bbcode_text = string


func load_JSON_ship_data() -> void:
	var JSON_path:String = "res://assets/data/ShipData.json"
	var file_string:String = FileAccess.get_file_as_string(JSON_path)
	var JSON_ship_data: Dictionary
	if file_string != null:
		JSON_ship_data = JSON.parse_string(file_string)
	else:
		push_warning("JSON loading from ShipData failed at " + JSON_path)
	
	if JSON_ship_data == null:
		push_error("ShipData JSON file parsing failed at " + JSON_path)
	
	SHIP_DATA = JSON_ship_data.get("ShipData")
	PLAYER_SHIP_STATS = JSON_ship_data.get("PlayerStats")
	ENEMY_SHIP_STATS = JSON_ship_data.get("EnemyStats")
