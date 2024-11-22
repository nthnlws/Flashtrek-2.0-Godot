extends Control

@export var federation_frame: CompressedTexture2D
@export var klingon_frame: CompressedTexture2D
@export var romulan_frame: CompressedTexture2D
@export var neutral_frame: CompressedTexture2D

@export var num_fed:int
@export var num_klin:int
@export var num_rom:int
@export var num_neut:int


var fed_ships = {
	"USS_Cerritos": Rect2(601, 1204, 301, 301),
	"EntTNG": Rect2(1806, 0, 301, 301),
	"Discovery": Rect2(1806, 1505, 301, 301)
	}
var klin_ships = {
	"brel": Rect2(301, 1504, 301, 301)
	}
	
var rom_ships = {
	"USS_Cerritos": Rect2(601, 1204, 301, 301)
	}
	
var neut_ships = {
	"Monaveen": Rect2(1204, 602, 301, 301),
	"dvor": Rect2(301, 903, 301, 301)
	}

var ship_types = [fed_ships, klin_ships, rom_ships, neut_ships]
var frame_textures = [federation_frame, klingon_frame, romulan_frame, neutral_frame]

# Called when the node enters the scene tree for the first time.
func _ready():
	var width = max(num_fed, num_klin, num_rom, num_neut)*100
	$VBoxContainer.position.x = (960/2) - (50)
	
	for i in range(num_fed):
		create_selection_frames(Utility.FACTION.FEDERATION, i)
	for i in range(num_klin):
		create_selection_frames(Utility.FACTION.KLINGON, i)
	for i in range(num_rom):
		create_selection_frames(Utility.FACTION.ROMULAN, i)
	for i in range(num_neut):
		create_selection_frames(Utility.FACTION.NEUTRAL, i)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func create_selection_frames(faction, i):
	# Create a container to group the frame and ship image
	var container = Control.new()
	#container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Create the frame
	var frame = TextureButton.new()
	frame.scale = Vector2(1.5, 1.5)

	# Create the ship image
	var ship_image = TextureRect.new()
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.region = Rect2(1204, 0, 301, 301)  # Default placeholder ship image
	ship_image.texture = atlas_texture
	ship_image.scale = Vector2(0.25, 0.25)
	ship_image.position = Vector2(13, 11)

	# Ensure the ship image is behind the frame
	ship_image.z_index = -1
	frame.z_index = 1  # Higher value ensures it appears on top

	# Add the container to the appropriate faction grid
	match faction:
		Utility.FACTION.FEDERATION:
			%FederationGrid.add_child(container)
			frame.texture_normal = federation_frame
			frame.name = "Fed" + str(i + 1)
			container.name = "Fed_Container_" + str(i + 1)
			if i < ship_types[Utility.FACTION.FEDERATION].size():
				atlas_texture.region = ship_types[Utility.FACTION.FEDERATION].values()[i]
		Utility.FACTION.KLINGON:
			%KlingonGrid.add_child(container)
			frame.texture_normal = klingon_frame
			frame.name = "Klin" + str(i + 1)
			container.name = "Klin_Container_" + str(i + 1)
			if i < ship_types[Utility.FACTION.KLINGON].size():
				atlas_texture.region = ship_types[Utility.FACTION.KLINGON].values()[i]
		Utility.FACTION.ROMULAN:
			%RomulanGrid.add_child(container)
			frame.texture_normal = romulan_frame
			frame.name = "Rom" + str(i + 1)
			container.name = "Rom_Container_" + str(i + 1)
			if i < ship_types[Utility.FACTION.ROMULAN].size():
				atlas_texture.region = ship_types[Utility.FACTION.ROMULAN].values()[i]
		Utility.FACTION.NEUTRAL:
			%NeutralGrid.add_child(container)
			frame.texture_normal = neutral_frame
			frame.name = "Neut" + str(i + 1)
			container.name = "Neut_Container_" + str(i + 1)
			if i < ship_types[Utility.FACTION.NEUTRAL].size():
				atlas_texture.region = ship_types[Utility.FACTION.NEUTRAL].values()[i]
		
	container.add_child(ship_image)
	container.add_child(frame)
