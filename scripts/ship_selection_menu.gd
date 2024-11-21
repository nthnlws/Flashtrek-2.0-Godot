extends Control

@export var federation_frame: CompressedTexture2D
@export var klingon_frame: CompressedTexture2D
@export var romulan_frame: CompressedTexture2D
@export var neutral_frame: CompressedTexture2D

@export var num_fed:int
@export var num_klin:int
@export var num_rom:int
@export var num_neut:int

var sprite_coords = {
	"USS_Cerritos": Rect2(601, 1204, 301, 301),
	"EntTNG": Rect2(1806, 0, 301, 301),
	"Discovery": Rect2(1806, 1505, 301, 301),
	"Monaveen": Rect2(1204, 602, 301, 301),
	"b'rel": Rect2(301, 1504, 301, 301),
}
var frame_textures = [federation_frame, klingon_frame, romulan_frame, neutral_frame]

# Called when the node enters the scene tree for the first time.
func _ready():
	var width = max(num_fed, num_klin, num_rom, num_neut)*100
	$VBoxContainer.position.x = (960/2) - (50)
	print($VBoxContainer.position.x)
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
	frame.texture_normal = get_frame_texture(faction)
	frame.scale = Vector2(1.5, 1.5)

	# Create the ship image
	var ship_image = TextureRect.new()
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.region = Rect2(1204, 0, 301, 301)  # Define the region in the atlas
	ship_image.texture = atlas_texture
	ship_image.scale = Vector2(0.25, 0.25)
	ship_image.position = Vector2(11, 11)
	ship_image.size_flags_horizontal = 4
	ship_image.size_flags_vertical = 4
	ship_image.anchor_left = 1
	ship_image.anchor_right = 0
	ship_image.anchor_top = 0
	ship_image.anchor_bottom = 1

	# Ensure the ship image is behind the frame
	ship_image.z_index = -1
	frame.z_index = 1  # Higher value ensures it appears on top

	# Add the ship image and frame to the container


	# Add the container to the appropriate faction grid
	match faction:
		Utility.FACTION.FEDERATION:
			%FederationGrid.add_child(container)
			frame.name = "Fed" + str(i + 1)
			container.name = "Fed_Container_" + str(i + 1)
			if i == 0: atlas_texture.region = sprite_coords["USS_Cerritos"]
			if i == 1: atlas_texture.region = sprite_coords["EntTNG"]
		Utility.FACTION.KLINGON:
			%KlingonGrid.add_child(container)
			frame.name = "Klin" + str(i + 1)
			container.name = "Klin_Container_" + str(i + 1)
			if i == 0: atlas_texture.region = sprite_coords["b'rel"]
		Utility.FACTION.ROMULAN:
			%RomulanGrid.add_child(container)
			frame.name = "Rom" + str(i + 1)
			container.name = "Rom_Container_" + str(i + 1)
		Utility.FACTION.NEUTRAL:
			%NeutralGrid.add_child(container)
			frame.name = "Neut" + str(i + 1)
			container.name = "Neut_Container_" + str(i + 1)
		
	container.add_child(ship_image)
	container.add_child(frame)

func get_frame_texture(faction):
	match faction:
		Utility.FACTION.FEDERATION:
			return federation_frame
		Utility.FACTION.KLINGON:
			return klingon_frame
		Utility.FACTION.ROMULAN:
			return romulan_frame
		Utility.FACTION.NEUTRAL:
			return neutral_frame
