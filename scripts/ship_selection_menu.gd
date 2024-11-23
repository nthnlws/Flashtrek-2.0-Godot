extends Control

var menu_state_machine: Node

@export var federation_frame: CompressedTexture2D
@export var klingon_frame: CompressedTexture2D
@export var romulan_frame: CompressedTexture2D
@export var neutral_frame: CompressedTexture2D

@export var federation_frame_pressed: CompressedTexture2D
@export var klingon_frame_pressed: CompressedTexture2D
@export var romulan_frame_pressed: CompressedTexture2D
@export var neutral_frame_pressed: CompressedTexture2D

@export var num_fed:int
@export var num_klin:int
@export var num_rom:int
@export var num_neut:int

@export var ship_rss = {
	"USS_Cerritos": preload("res://resources/California_class_enemy.tres"),
	"EntTNG": preload("res://resources/enterpriseTNG_enemy.tres"),
	
	"brel": preload("res://resources/BirdOfPrey_enemy.tres"),
	
	"Monaveen": preload("res://resources/Monaveen_enemy.tres")
	#"dvor": 
}


var fed_ships = {
	"USS_Cerritos": Rect2(601, 1210, 301, 301),
	"EntTNG": Rect2(1806, 0, 301, 301),
	"Discovery": Rect2(1800, 1510, 301, 301)
	}
	
var klin_ships = {
	"brel": Rect2(303, 1508, 301, 301)
	}
	
var rom_ships = {
	"USS_Cerritos": Rect2(601, 1210, 301, 301),
	}
	
var neut_ships = {
	"Monaveen": Rect2(1204, 602, 301, 301),
	"dvor": Rect2(301, 903, 301, 301)
	}

var ship_types = [fed_ships, klin_ships, rom_ships, neut_ships]
var frame_textures = [federation_frame, klingon_frame, romulan_frame, neutral_frame]

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_node("..").name == "Menus":
		menu_state_machine = get_node("..")
	
	var width = max(num_fed, num_klin, num_rom, num_neut)*100
	var middle_pos = (960/2) - (50)
	$Grid.position.x = middle_pos - 170
	
	for i in range(num_fed):
		create_selection_frames(Utility.FACTION.FEDERATION, i)
	for i in range(num_klin):
		create_selection_frames(Utility.FACTION.KLINGON, i)
	for i in range(num_rom):
		create_selection_frames(Utility.FACTION.ROMULAN, i)
	for i in range(num_neut):
		create_selection_frames(Utility.FACTION.NEUTRAL, i)

func create_selection_frames(faction, i):
	# Create a container to group the frame and ship image
	var container = Control.new()

	# Create the frame
	var frame = TextureButton.new()
	frame.scale = Vector2(1.5, 1.5)
	frame.name = "Placeholder"

	# Create the ship image
	var ship_image = TextureRect.new()
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.region = Rect2(1204, 0, 301, 301) #Placeholder image
	ship_image.texture = atlas_texture
	ship_image.scale = Vector2(0.25, 0.25)
	ship_image.position = Vector2(11, 11)

	# Ensure the ship image is behind the frame
	ship_image.z_index = 1
	frame.z_index = -1

	# Add the container to the appropriate faction grid
	match faction:
		Utility.FACTION.FEDERATION:
			%FederationGrid.add_child(container)
			frame.texture_normal = federation_frame
			frame.texture_hover = federation_frame_pressed
			container.name = "Fed_Container_" + str(i + 1)
			if i < ship_types[Utility.FACTION.FEDERATION].size():
				atlas_texture.region = ship_types[Utility.FACTION.FEDERATION].values()[i]
				frame.name = ship_types[Utility.FACTION.FEDERATION].keys()[i]
		Utility.FACTION.KLINGON:
			%KlingonGrid.add_child(container)
			frame.texture_normal = klingon_frame
			frame.texture_hover = klingon_frame_pressed
			container.name = "Klin_Container_" + str(i + 1)
			if i < ship_types[Utility.FACTION.KLINGON].size():
				atlas_texture.region = ship_types[Utility.FACTION.KLINGON].values()[i]
				frame.name = ship_types[Utility.FACTION.KLINGON].keys()[i]
		Utility.FACTION.ROMULAN:
			%RomulanGrid.add_child(container)
			frame.texture_normal = romulan_frame
			frame.texture_hover = romulan_frame_pressed
			container.name = "Rom_Container_" + str(i + 1)
			if i < ship_types[Utility.FACTION.ROMULAN].size():
				atlas_texture.region = ship_types[Utility.FACTION.ROMULAN].values()[i]
				frame.name = ship_types[Utility.FACTION.ROMULAN].keys()[i]
				
		Utility.FACTION.NEUTRAL:
			%NeutralGrid.add_child(container)
			frame.texture_normal = neutral_frame
			frame.texture_hover = neutral_frame_pressed
			container.name = "Neut_Container_" + str(i + 1)
			if i < ship_types[Utility.FACTION.NEUTRAL].size():
				atlas_texture.region = ship_types[Utility.FACTION.NEUTRAL].values()[i]
				frame.name = ship_types[Utility.FACTION.NEUTRAL].keys()[i]
		
	container.add_child(ship_image)
	container.add_child(frame)
	
	frame.mouse_entered.connect(update_ship_stats.bind(frame.name))


func update_ship_stats(ship_name):
	if ship_rss.has(ship_name):
		var match_rss = ship_rss[ship_name]
		
	elif ship_name != "Placeholder":
		print("No RSS file found")


func _on_close_menu_button_pressed():
	self.visible = false
	menu_state_machine.current_state = menu_state_machine.MenuState.NONE
