extends Control

var menu_state_machine: Node

@onready var ambience:AudioStreamPlayer = $ambience

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

var ship_list: Dictionary = Utility.ship_sprites

@export var ship_rss: Dictionary = {
	"California_Class": preload("res://resources/Ships/California_class_enemy.tres"),
	"Galaxy_Class": preload("res://resources/Ships/enterpriseTNG_enemy.tres"),
	
	"Brel_Class": preload("res://resources/Ships/BirdOfPrey_enemy.tres"),
	
	"Monaveen": preload("res://resources/Ships/Monaveen_enemy.tres")
}


var fed_ships: Dictionary = {
	Utility.SHIP_NAMES.Galaxy_Class: ship_list[Utility.SHIP_NAMES.Galaxy_Class],
	Utility.SHIP_NAMES.California_Class: ship_list[Utility.SHIP_NAMES.California_Class],
	Utility.SHIP_NAMES.Cardenas_Class: ship_list[Utility.SHIP_NAMES.Cardenas_Class]
	}
	
var klin_ships: Dictionary = {
	Utility.SHIP_NAMES.Brel_Class: ship_list[Utility.SHIP_NAMES.Brel_Class]
	}
	
var rom_ships: Dictionary = {
	Utility.SHIP_NAMES.California_Class: ship_list[Utility.SHIP_NAMES.California_Class]
	}
	
var neut_ships: Dictionary = {
	Utility.SHIP_NAMES.Monaveen: ship_list[Utility.SHIP_NAMES.Monaveen],
	Utility.SHIP_NAMES.DKora_Marauder: ship_list[Utility.SHIP_NAMES.DKora_Marauder]
	}

var frame_textures: Array = [federation_frame, klingon_frame, romulan_frame, neutral_frame]

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_parent().name == "Menus":
		menu_state_machine = get_node("..")
	
	var width: int = max(num_fed, num_klin, num_rom, num_neut)*100
	var middle_pos: float = (960/2) - (50)
	$Grid.position.x = middle_pos - 170
	
	for i in range(num_fed):
		create_selection_frames(Utility.FACTION.FEDERATION, i)
	for i in range(num_klin):
		create_selection_frames(Utility.FACTION.KLINGON, i)
	for i in range(num_rom):
		create_selection_frames(Utility.FACTION.ROMULAN, i)
	for i in range(num_neut):
		create_selection_frames(Utility.FACTION.NEUTRAL, i)
		

func _process(delta):
	if visible == true:
		if ambience.playing == false:
			start_ambience()
	else:
		if ambience.playing: ambience.stop()
		if %ship_name.text != "": clear_stats()
		

func clear_stats():
		%ship_name.text = "Ship Name: "
		%faction.text = "Faction: "
		%health_stat.text = "Health: "
		%shield_stat.text = "Shield: "
		%weapon.text = "Default Weapon: "
		%speed_stat.text = "Max Speed: "
		%maneuver_stat.text = "Maneuverability: "
		%antimatter_stat.text = "Antimatter: "
		
		
func start_ambience():
	ambience.volume_db = -25
	ambience.play()
	var tween: Object = create_tween()
	tween.tween_property(ambience, "volume_db", -20, 4.0)
	
	
func create_selection_frames(faction: Utility.FACTION, i: int):
	# Create a container to group the frame and ship image
	var container: Control = Control.new()

	# Create the frame
	var frame: TextureButton = TextureButton.new()
	frame.scale = Vector2(1.5, 1.5)
	frame.name = "Placeholder"

	# Create the ship image
	var ship_image: TextureRect = TextureRect.new()
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://assets/textures/ships/ship_sprites.png")
	atlas_texture.region = ship_list[Utility.SHIP_NAMES.D5_Class]
	ship_image.texture = atlas_texture
	ship_image.scale = Vector2(1.55, 1.55)
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
			if i < fed_ships.size():
				atlas_texture.region = fed_ships.values()[i]
				var enum_key: int = fed_ships.keys()[i]
				frame.name = str(Utility.SHIP_NAMES.keys()[enum_key])
				
		Utility.FACTION.KLINGON:
			%KlingonGrid.add_child(container)
			frame.texture_normal = klingon_frame
			frame.texture_hover = klingon_frame_pressed
			container.name = "Klin_Container_" + str(i + 1)
			if i < klin_ships.size():
				atlas_texture.region = klin_ships.values()[i]
				var enum_key: int = klin_ships.keys()[i]
				frame.name = str(Utility.SHIP_NAMES.keys()[enum_key])
				
		Utility.FACTION.ROMULAN:
			%RomulanGrid.add_child(container)
			frame.texture_normal = romulan_frame
			frame.texture_hover = romulan_frame_pressed
			container.name = "Rom_Container_" + str(i + 1)
			if i < rom_ships.size():
				atlas_texture.region = rom_ships.values()[i]
				var enum_key: int = rom_ships.keys()[i]
				frame.name = str(Utility.SHIP_NAMES.keys()[enum_key])
				
		Utility.FACTION.NEUTRAL:
			%NeutralGrid.add_child(container)
			frame.texture_normal = neutral_frame
			frame.texture_hover = neutral_frame_pressed
			container.name = "Neut_Container_" + str(i + 1)
			if i < neut_ships.size():
				atlas_texture.region = neut_ships.values()[i]
				var enum_key: int = neut_ships.keys()[i]
				frame.name = str(Utility.SHIP_NAMES.keys()[enum_key])
		
	container.add_child(ship_image)
	container.add_child(frame)

	frame.mouse_entered.connect(update_ship_stats.bind(frame.name))

func update_ship_stats(ship_name: String):
	if ship_rss.has(ship_name):
		var enemy_rss = ship_rss[ship_name]
		%ship_name.text = "Ship Name: " + Utility.UI_ship_lime + ship_name.replace("_", " ")
		%health_stat.text = "Health: " + str(enemy_rss.max_hp)
		%shield_stat.text = "Shield: " + str(enemy_rss.max_shield_health)
		%weapon.text = "Default Weapon: " + str(enemy_rss.weapon.resource_path.get_file().get_basename()).to_pascal_case()
		%speed_stat.text = "Max Speed: " + str(enemy_rss.default_speed)
		%maneuver_stat.text = "Maneuverability: " + str(enemy_rss.rotation_rate)
		match enemy_rss.class_faction:
			0: # Federation
				%faction.text = "Faction: " + Utility.fed_blue + str(Utility.FACTION.keys()[enemy_rss.class_faction]).to_pascal_case()
			1: # Klingon
				%faction.text = "Faction: " + Utility.klin_red + str(Utility.FACTION.keys()[enemy_rss.class_faction]).to_pascal_case()
			2: # Romulan
				%faction.text = "Faction: " + Utility.rom_green + str(Utility.FACTION.keys()[enemy_rss.class_faction]).to_pascal_case()
			3: # Neutral
				%faction.text = "Faction: " + Utility.neut_cyan + str(Utility.FACTION.keys()[enemy_rss.class_faction]).to_pascal_case()
		%antimatter_stat.text = "Antimatter: " + str(enemy_rss.max_antimatter)
		
	elif ship_name != "Placeholder":
		%ship_name.text = "Ship Name: Placeholder"
		%faction.text = "Faction: Placeholder"
		%health_stat.text = "Health: Placeholder"
		%shield_stat.text = "Shield: Placeholder"
		%weapon.text = "Default Weapon: Placeholder"
		%speed_stat.text = "Max Speed: Placeholder"
		%maneuver_stat.text = "Maneuverability: Placeholder"
		%antimatter_stat.text = "Antimatter: Placeholder"

func _on_close_menu_button_pressed():
	self.visible = false
	menu_state_machine.current_state = menu_state_machine.MenuState.NONE
