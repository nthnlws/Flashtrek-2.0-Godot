extends Control

#@onready var coll_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var sprite: Sprite2D = $Sprite
@onready var area: Area2D = $Area2D
@onready var coll: CollisionPolygon2D = $Area2D/CollisionPolygon2D


var sprite_areas: Array[Rect2] = [
	Rect2(0, 0, 48, 48),
	Rect2(48, 0, 48, 48),
	Rect2(96, 0, 48, 48),
	Rect2(144, 0, 48, 48),
	Rect2(192, 0, 48, 48),
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

var ship_names: Array = [
	"Merchantman",
	"Keldon_Class",
	"batlh_Class",
	"JemHadar",
	"sech_Class",
	"Pathfinder_Class",
	"Steamrunner_Class",
	"Soyuz_Class",
	"Miranda_Class",
	"Nimitz_Class",
	"Freedom_Class",
	"Intrepid_Class",
	"Niagara_Class",
	"Talarian_Freighter",
	"Galor_Class",
	"Bajoran_Freighter",
	"daSpu_Class",
	"Klingon_Bird_of_Prey_Discovery_era",
	"Walker_Class",
	"Sovereign_Class",
	"Malachowski_Class",
	"Miranda_Class_Lantree_variant",
	"Nova_Class",
	"Constitution_Class_Strange_New_Worlds",
	"Nova_Class_Rhode_Island_variant",
	"New_Orleans_Class",
	"DKora_Marauder",
	"Hideki_Class",
	"Qugh_Class",
	"Hiawatha_Class",
	"Mars_Synth_Defense_Ship",
	"Intrepid_Class_Aeroshuttle",
	"Gagarin_Class",
	"Saber_Class",
	"Miranda_Class_Saratoga_variant",
	"Parliament_Class",
	"Georgiou_Class",
	"Defiant_Class",
	"Cheyenne_Class",
	"Peregrine_Class",
	"Odyssey_Class",
	"D5_Class",
	"Risian_Corvette",
	"Breen_Interceptor",
	"Bajoran_Interceptor",
	"Oberth_Class",
	"Cardenas_Class",
	"Vesta_Class",
	"Miranda_Class_Antares_variant",
	"Challenger_Class",
	"Constitution_II_Class",
	"Constitution_III_Class",
	"Galaxy_Class",
	"Maquis_Raider",
	"chargh_Class",
	"Wallenberg_Class",
	"Dhailkhina_Class",
	"Sampson_Class",
	"Excelsior_Class",
	"Class_III_Neutronic_Fuel_Carrier_Kobayashi_Maru",
	"Shepard_Class",
	"Norway_Class",
	"California_Class",
	"Galaxy_Class_Venture_variant",
	"Springfield_Class",
	"Theta_Class",
	"Groumall_Freighter",
	"Tellarite_Cruiser",
	"Magee_Class",
	"bortaS_bIr_Class",
	"Dia_Vectau_Class",
	"Hernandez_Class",
	"Excelsior_Class_Refit",
	"Luna_Class",
	"Edison_Class",
	"Constellation_Class",
	"Sagan_Class",
	"Sutherland_Class",
	"Nebula_Class_Phoenix_variant",
	"La_Sirena",
	"Monaveen",
	"Risian_Luxury_Cruiser",
	"Brel_Class",
	"Dderidex_Class",
	"Engle_Class",
	"Reliant_Class",
	"Ross_Class",
	"Akira_Class",
	"Ambassador_Class",
	"Excelsior_II_Class",
	"Hoover_Class",
	"Nebula_Class",
]

var collision_array: Array[PackedVector2Array] = []

func _ready() -> void:
	for area in sprite_areas:
		sprite.texture.region = area
		var poly: PackedVector2Array = sprite_to_polygon()
		collision_array.append(poly)
	save_collision_array_to_txt("C:/Users/nthnl/Desktop/collision_data.txt")

func sprite_to_polygon():
	var new_area:CollisionPolygon2D
	if area.get_child(0):
		new_area = area.get_child(0)
		area.remove_child(new_area)
		
	var image: Image = sprite.texture.get_image()
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)

	var polys = bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, sprite.texture.get_size()))
	for poly in polys:
		var collision_polygon = CollisionPolygon2D.new()
		collision_polygon.polygon = poly
		area.add_child(collision_polygon)

		# Generated polygon will not take into account the half-width and half-height offset
		# of the image when "centered" is on. So move it backwards by this amount so it lines up.
		if sprite.centered:
			collision_polygon.position -= Vector2(image.get_size()) / 2.0
	
	return area.get_child(0).polygon
	

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
