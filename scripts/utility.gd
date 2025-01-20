extends Node
class_name game_data

enum PLAYER_TYPE { BIRDOFPREY, ENTERPRISETOS, JEM_HADAR, ENTERPRISETNG, MONAVEEN, CALIFORNIA }
enum ENEMY_TYPE { BIRDOFPREY, ENTERPRISETOS, JEM_HADAR, ENTERPRISETNG, MONAVEEN, CALIFORNIA }
enum FACTION { FEDERATION, KLINGON, ROMULAN, NEUTRAL }

enum SHIP_NAMES {
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
	Klingon_Bird_of_Prey_Discovery_era,
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

var ship_sprites = {
	SHIP_NAMES.Merchantman: Rect2(0, 0, 48, 48),
	SHIP_NAMES.Keldon_Class: Rect2(48, 0, 48, 48),
	SHIP_NAMES.batlh_Class: Rect2(96, 0, 48, 48),
	SHIP_NAMES.JemHadar: Rect2(144, 0, 48, 48),
	SHIP_NAMES.sech_Class: Rect2(192, 0, 48, 48),
	SHIP_NAMES.Pathfinder_Class: Rect2(288, 0, 48, 48),
	SHIP_NAMES.Steamrunner_Class: Rect2(336, 0, 48, 48),
	SHIP_NAMES.Soyuz_Class: Rect2(384, 0, 48, 48),
	SHIP_NAMES.Miranda_Class: Rect2(432, 0, 48, 48),
	SHIP_NAMES.Nimitz_Class: Rect2(480, 0, 48, 48),
	SHIP_NAMES.Freedom_Class: Rect2(528, 0, 48, 48),
	SHIP_NAMES.Intrepid_Class: Rect2(576, 0, 48, 48),
	SHIP_NAMES.Niagara_Class: Rect2(624, 0, 48, 48),
	SHIP_NAMES.Talarian_Freighter: Rect2(0, 48, 48, 48),
	SHIP_NAMES.Galor_Class: Rect2(48, 48, 48, 48),
	SHIP_NAMES.Bajoran_Freighter: Rect2(96, 48, 48, 48),
	SHIP_NAMES.daSpu_Class: Rect2(144, 48, 48, 48),
	SHIP_NAMES.Klingon_Bird_of_Prey_Discovery_era: Rect2(192, 48, 48, 48),
	SHIP_NAMES.Walker_Class: Rect2(288, 48, 48, 48),
	SHIP_NAMES.Sovereign_Class: Rect2(336, 48, 48, 48),
	SHIP_NAMES.Malachowski_Class: Rect2(384, 48, 48, 48),
	SHIP_NAMES.Miranda_Class_Lantree_variant: Rect2(432, 48, 48, 48),
	SHIP_NAMES.Nova_Class: Rect2(480, 48, 48, 48),
	SHIP_NAMES.Constitution_Class_Strange_New_Worlds: Rect2(528, 48, 48, 48),
	SHIP_NAMES.Nova_Class_Rhode_Island_variant: Rect2(576, 48, 48, 48),
	SHIP_NAMES.New_Orleans_Class: Rect2(624, 48, 48, 48),
	SHIP_NAMES.DKora_Marauder: Rect2(0, 96, 48, 48),
	SHIP_NAMES.Hideki_Class: Rect2(48, 96, 48, 48),
	SHIP_NAMES.Qugh_Class: Rect2(96, 96, 48, 48),
	SHIP_NAMES.Hiawatha_Class: Rect2(144, 96, 48, 48),
	SHIP_NAMES.Mars_Synth_Defense_Ship: Rect2(192, 96, 48, 48),
	SHIP_NAMES.Intrepid_Class_Aeroshuttle: Rect2(288, 96, 48, 48),
	SHIP_NAMES.Gagarin_Class: Rect2(336, 96, 48, 48),
	SHIP_NAMES.Saber_Class: Rect2(384, 96, 48, 48),
	SHIP_NAMES.Miranda_Class_Saratoga_variant: Rect2(432, 96, 48, 48),
	SHIP_NAMES.Parliament_Class: Rect2(480, 96, 48, 48),
	SHIP_NAMES.Georgiou_Class: Rect2(528, 96, 48, 48),
	SHIP_NAMES.Defiant_Class: Rect2(576, 96, 48, 48),
	SHIP_NAMES.Cheyenne_Class: Rect2(624, 96, 48, 48),
	SHIP_NAMES.Peregrine_Class: Rect2(0, 144, 48, 48),
	SHIP_NAMES.Odyssey_Class: Rect2(48, 144, 48, 96),
	SHIP_NAMES.D5_Class: Rect2(96, 144, 48, 48),
	SHIP_NAMES.Risian_Corvette: Rect2(144, 144, 48, 48),
	SHIP_NAMES.Breen_Interceptor: Rect2(192, 144, 48, 48),
	SHIP_NAMES.Bajoran_Interceptor: Rect2(240, 144, 48, 48),
	SHIP_NAMES.Oberth_Class: Rect2(288, 144, 48, 48),
	SHIP_NAMES.Cardenas_Class: Rect2(336, 144, 48, 48),
	SHIP_NAMES.Vesta_Class: Rect2(384, 144, 48, 48),
	SHIP_NAMES.Miranda_Class_Antares_variant: Rect2(432, 144, 48, 48),
	SHIP_NAMES.Challenger_Class: Rect2(480, 144, 48, 48),
	SHIP_NAMES.Constitution_II_Class: Rect2(528, 144, 48, 48),
	SHIP_NAMES.Constitution_III_Class: Rect2(576, 144, 48, 48),
	SHIP_NAMES.Galaxy_Class: Rect2(624, 144, 48, 48),
	SHIP_NAMES.Maquis_Raider: Rect2(0, 192, 48, 48),
	SHIP_NAMES.chargh_Class: Rect2(96, 192, 48, 48),
	SHIP_NAMES.Wallenberg_Class: Rect2(144, 192, 48, 48),
	SHIP_NAMES.Dhailkhina_Class: Rect2(240, 192, 48, 48),
	SHIP_NAMES.Sampson_Class: Rect2(288, 192, 48, 48),
	SHIP_NAMES.Excelsior_Class: Rect2(336, 192, 48, 48),
	SHIP_NAMES.Class_III_Neutronic_Fuel_Carrier_Kobayashi_Maru: Rect2(384, 192, 48, 48),
	SHIP_NAMES.Shepard_Class: Rect2(432, 192, 48, 48),
	SHIP_NAMES.Norway_Class: Rect2(480, 192, 48, 48),
	SHIP_NAMES.California_Class: Rect2(528, 192, 48, 48),
	SHIP_NAMES.Galaxy_Class_Venture_variant: Rect2(576, 192, 48, 48),
	SHIP_NAMES.Springfield_Class: Rect2(624, 192, 48, 48),
	SHIP_NAMES.Theta_Class: Rect2(0, 240, 48, 48),
	SHIP_NAMES.Groumall_Freighter: Rect2(48, 240, 48, 96),
	SHIP_NAMES.Tellarite_Cruiser: Rect2(96, 240, 48, 48),
	SHIP_NAMES.Magee_Class: Rect2(144, 240, 48, 48),
	SHIP_NAMES.bortaS_bIr_Class: Rect2(192, 240, 48, 48),
	SHIP_NAMES.Dia_Vectau_Class: Rect2(240, 240, 48, 48),
	SHIP_NAMES.Hernandez_Class: Rect2(288, 240, 48, 48),
	SHIP_NAMES.Excelsior_Class_Refit: Rect2(336, 240, 48, 48),
	SHIP_NAMES.Luna_Class: Rect2(384, 240, 48, 48),
	SHIP_NAMES.Edison_Class: Rect2(432, 240, 48, 48),
	SHIP_NAMES.Constellation_Class: Rect2(480, 240, 48, 48),
	SHIP_NAMES.Sagan_Class: Rect2(528, 240, 48, 48),
	SHIP_NAMES.Sutherland_Class: Rect2(576, 240, 48, 48),
	SHIP_NAMES.Nebula_Class_Phoenix_variant: Rect2(624, 240, 48, 48),
	SHIP_NAMES.La_Sirena: Rect2(0, 288, 48, 48),
	SHIP_NAMES.Monaveen: Rect2(96, 288, 48, 48),
	SHIP_NAMES.Risian_Luxury_Cruiser: Rect2(144, 288, 48, 48),
	SHIP_NAMES.Brel_Class: Rect2(192, 288, 48, 48),
	SHIP_NAMES.Dderidex_Class: Rect2(240, 288, 48, 48),
	SHIP_NAMES.Engle_Class: Rect2(288, 288, 48, 48),
	SHIP_NAMES.Reliant_Class: Rect2(336, 288, 48, 48),
	SHIP_NAMES.Ross_Class: Rect2(384, 288, 48, 48),
	SHIP_NAMES.Akira_Class: Rect2(432, 288, 48, 48),
	SHIP_NAMES.Ambassador_Class: Rect2(480, 288, 48, 48),
	SHIP_NAMES.Excelsior_II_Class: Rect2(528, 288, 48, 48),
	SHIP_NAMES.Hoover_Class: Rect2(576, 288, 48, 48),
	SHIP_NAMES.Nebula_Class: Rect2(624, 288, 48, 48),
}

var ship_rss = {
	"Merchantman": null,
	"Keldon-Class": null,
	"batlh-Class": null,
	"Jem'Hadar Attack Ship": preload("res://resources/Jem_Hadar_enemy.tres"),
	"sech-Class": null,
	"Pathfinder-Class": null,
	"Steamrunner-Class": null,
	"Soyuz-Class": null,
	"Miranda-Class": null,
	"Nimitz-Class": null,
	"Freedom-Class": null,
	"Intrepid-Class": null,
	"Niagara-Class": null,
	"Talarian Freighter": null,
	"Galor-Class": null,
	"Bajoran Freighter": null,
	"daSpu'-Class": null,
	"Klingon Bird-of-Prey (Discovery era)": null,
	"Walker-Class": null,
	"Sovereign-Class": null,
	"Malachowski-Class": null,
	"Miranda-Class (Lantree variant)": null,
	"Nova-Class": null,
	"Constitution-Class (Strange New Worlds)": null,
	"Nova-Class (Rhode Island variant)": null,
	"New Orleans-Class": null,
	"D'Kora Marauder": null,
	"Hideki-Class": null,
	"Qugh-Class": null,
	"Hiawatha-Class": null,
	"Mars Synth Defense Ship": null,
	"Intrepid-Class Aeroshuttle": null,
	"Gagarin-Class": null,
	"Saber-Class": null,
	"Miranda-Class (Saratoga variant)": null,
	"Parliament-Class": null,
	"Georgiou-Class": null,
	"Defiant-Class": null,
	"Cheyenne-Class": null,
	"Peregrine-Class": null,
	"Odyssey-Class": null,
	"D5-Class": null,
	"Risian Corvette": null,
	"Breen Interceptor": null,
	"Bajoran Interceptor": null,
	"Oberth-Class": null,
	"Cardenas-Class": null,
	"Vesta-Class": null,
	"Miranda-Class (Antares variant)": null,
	"Challenger-Class": null,
	"Constitution-II-Class": null,
	"Constitution-III-Class": null,
	"Galaxy-Class": preload("res://resources/enterpriseTNG_enemy.tres"),
	"Maquis Raider": null,
	"chargh-Class": null,
	"Wallenberg-Class": null,
	"Dhailkhina-Class": null,
	"Sampson-Class": null,
	"Excelsior-Class": null,
	"Class III Neutronic Fuel Carrier (Kobayashi Maru)": null,
	"Shepard-Class": null,
	"Norway-Class": null,
	"California-Class": preload("res://resources/California_class_enemy.tres"),
	"Galaxy-Class (Venture variant)": null,
	"Springfield-Class": null,
	"Theta-Class": null,
	"Groumall Freighter":null,
	"Tellarite Cruiser":null,
	"Magee-Class": null,
	"bortaS bIr-Class": null,
	"Dia Vectau-Class": null,
	"Hernandez-Class": null,
	"Excelsior-Class Refit": null,
	"Luna-Class": null,
	"Edison-Class": null,
	"Constellation-Class": null,
	"Sagan-Class": null,
	"Sutherland-Class": null,
	"Nebula-Class (Phoenix variant)": null,
	"La Sirena": null,
	"Monaveen": preload("res://resources/Monaveen_enemy.tres"),
	"Risian Luxury Cruiser": null,
	"B'rel-Class": preload("res://resources/BirdOfPrey_enemy.tres"),
	"D'deridex-Class": null,
	"Engle-Class": null,
	"Reliant-Class": null,
	"Ross-Class": null,
	"Akira-Class": null,
	"Ambassador-Class": null,
	"Excelsior-II-Class": null,
	"Hoover-Class": null,
	"Nebula-Class": null
}


var mainScene:Node = null # Set by main scene on _init()

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

func _ready() -> void:
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()
	
	
func _input(event):
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
func play_click_sound(volume): 
	var sound_array_length = sound_array.size() - 1

	match sound_array_location:
		sound_array_length: # When location in array = array size, shuffle array and reset location
			var default_db = sound_array[sound_array_location].volume_db
			var effective_volume = default_db + volume
			sound_array[sound_array_location].set_volume_db(effective_volume)
			sound_array[sound_array_location].stop() # Ensure the sound is stopped before playing
			sound_array[sound_array_location].play()
			sound_array[sound_array_location].set_volume_db(default_db)
			sound_array.shuffle()
			sound_array_location = 0
		_: # Runs for all array values besides last
			var default_db = sound_array[sound_array_location].volume_db
			var effective_volume = default_db + volume
			sound_array[sound_array_location].set_volume_db(effective_volume)
			sound_array[sound_array_location].stop() # Ensure the sound is stopped before playing
			sound_array[sound_array_location].play()
			sound_array[sound_array_location].set_volume_db(default_db)
			sound_array_location += 1
