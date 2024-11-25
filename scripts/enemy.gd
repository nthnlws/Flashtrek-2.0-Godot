extends Resource
class_name Enemy

enum CLASS_SIZE { SMALL, MEDIUM, LARGE }
enum SHIP_SPRITES {
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

@export var enemy_name: SHIP_SPRITES
@export var class_size: CLASS_SIZE
@export var class_faction: Utility.FACTION


var sprite_scale: Vector2:
	get: 
		match class_size:
			CLASS_SIZE.SMALL:
				return Vector2(2.5, 2.5)
			CLASS_SIZE.MEDIUM:
				return Vector2(4, 4)
			CLASS_SIZE.LARGE:
				return Vector2(5, 5)
		return Vector2(1, 1)

var shield_multipler:Vector2 = Vector2(5, 5) # Default shield size for normal (medium) craft

var class_shield_scale:Vector2 = Vector2(1, 1): # Default scaling 
	get:
		match class_size:
			CLASS_SIZE.SMALL:
				return shield_multipler * Vector2(2.5, 2.5)
			CLASS_SIZE.MEDIUM:
				return shield_multipler * Vector2(4, 4)
			CLASS_SIZE.LARGE:
				return shield_multipler * Vector2(6, 6)
		return shield_multipler

@export var ship_shield_scale: Vector2 = Vector2(1, 1)

var collision_scale:float

@export var default_speed: int = 60
@export var rotation_rate: float = 3
@export var shield_on: bool = true
@export var rate_of_fire: float = 1.0
@export var muzzle_pos: Vector2 = Vector2(0, -12)
@export var RANDOMNESS_ANGLE_DEGREES: float = 3.0
@export var detection_radius: int = 1200

@export var max_hp:int = 100
@export var max_shield_health:int = 50

@export var sprite_texture: Texture = preload("res://assets/textures/ships/ship_sprites.png")

@export var torpedo: PackedScene = preload("res://scenes/torpedo.tscn")
@export var collision_shape: ConvexPolygonShape2D
