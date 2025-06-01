extends Control

var menu_state_machine: Node

@onready var ambience:AudioStreamPlayer = $ambience
@onready var warp_stat: RichTextLabel = %warp_stat

@export var grid_tile_width = 6

@export var sprite_sheet := preload("res://assets/textures/ships/ship_sprites.png")
@export var federation_frame: CompressedTexture2D
@export var klingon_frame: CompressedTexture2D
@export var romulan_frame: CompressedTexture2D
@export var neutral_frame: CompressedTexture2D

@export var federation_frame_pressed: CompressedTexture2D
@export var klingon_frame_pressed: CompressedTexture2D
@export var romulan_frame_pressed: CompressedTexture2D
@export var neutral_frame_pressed: CompressedTexture2D


var fed_ships: Array = [
	Utility.SHIP_TYPES.Galaxy_Class,
	Utility.SHIP_TYPES.California_Class,
	Utility.SHIP_TYPES.Cardenas_Class,]


var klin_ships: Array = [
	Utility.SHIP_TYPES.Brel_Class,]


var rom_ships: Array = [
	Utility.SHIP_TYPES.Dderidex_Class,]


var neut_ships: Array = [
	Utility.SHIP_TYPES.Monaveen,
	Utility.SHIP_TYPES.DKora_Marauder,]


var frame_textures: Array = [federation_frame, klingon_frame, romulan_frame, neutral_frame]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_parent().name == "Menus":
		menu_state_machine = get_node("..")
	
	var middle_pos: int = (960/2) - (50)
	#%Grid.position.x = middle_pos - 170
	
	for ship in fed_ships:
		create_selection_frames(Utility.FACTION.FEDERATION, ship)
	for ship in klin_ships:
		create_selection_frames(Utility.FACTION.KLINGON, ship)
	for ship in rom_ships:
		create_selection_frames(Utility.FACTION.ROMULAN, ship)
	for ship in neut_ships:
		create_selection_frames(Utility.FACTION.NEUTRAL, ship)
	
	#Create Placeholder frames
	for i in range(grid_tile_width- fed_ships.size()):
		create_placeholder_frame(Utility.FACTION.FEDERATION)
	for i in range(grid_tile_width- klin_ships.size()):
		create_placeholder_frame(Utility.FACTION.KLINGON)
	for i in range(grid_tile_width- rom_ships.size()):
		create_placeholder_frame(Utility.FACTION.ROMULAN)
	for i in range(grid_tile_width- neut_ships.size()):
		create_placeholder_frame(Utility.FACTION.NEUTRAL)


func _process(delta: float) -> void:
	if visible == true:
		if ambience.playing == false:
			start_ambience()
	else:
		if ambience.playing: ambience.stop()
		if %ship_name.text != "": clear_stats()


func clear_stats() -> void:
		%ship_name.text = "Ship Name: "
		%faction.text = "Faction: "
		%health_stat.text = "Health: "
		%shield_stat.text = "Shield: "
		%weapon.text = "Default Weapon: "
		%speed_stat.text = "Max Speed: "
		%maneuver_stat.text = "Maneuverability: "
		warp_stat.text = "Warp Range: "


func start_ambience() -> void:
	ambience.volume_db = -25
	ambience.play()
	var tween: Tween = create_tween()
	tween.tween_property(ambience, "volume_db", -20, 4.0)


func create_selection_frames(faction: Utility.FACTION, i: Utility.SHIP_TYPES) -> void:
	# Create a container to group the frame and ship image
	var fleet_data:Array = Utility.SHIP_DATA.values()
	var ship_data:Dictionary = fleet_data[i]
	var container: Control = Control.new()

	# Create the frame
	var frame: TextureButton = TextureButton.new()
	frame.scale = Vector2(1.3, 1.3)

	# Create the ship image
	var ship_image: TextureRect = TextureRect.new()
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = sprite_sheet
	atlas_texture.filter_clip = true
	ship_image.texture = atlas_texture
	ship_image.scale = Vector2(1.2, 1.2)
	ship_image.position = Vector2(14, 14)

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
			#if i < fed_ships.size():
			atlas_texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
			frame.name = str(Utility.SHIP_TYPES.keys()[i])
				
		Utility.FACTION.KLINGON:
			%KlingonGrid.add_child(container)
			frame.texture_normal = klingon_frame
			frame.texture_hover = klingon_frame_pressed
			container.name = "Klin_Container_" + str(i + 1)
			#if i < klin_ships.size():
			atlas_texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
			frame.name = str(Utility.SHIP_TYPES.keys()[i])
				
		Utility.FACTION.ROMULAN:
			%RomulanGrid.add_child(container)
			frame.texture_normal = romulan_frame
			frame.texture_hover = romulan_frame_pressed
			container.name = "Rom_Container_" + str(i + 1)
			#if i < rom_ships.size():
			atlas_texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
			frame.name = str(Utility.SHIP_TYPES.keys()[i])
				
		Utility.FACTION.NEUTRAL:
			%NeutralGrid.add_child(container)
			frame.texture_normal = neutral_frame
			frame.texture_hover = neutral_frame_pressed
			container.name = "Neut_Container_" + str(i + 1)
			#if i < neut_ships.size():
			atlas_texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
			frame.name = str(Utility.SHIP_TYPES.keys()[i])
		
	container.add_child(ship_image)
	container.add_child(frame)

	frame.mouse_entered.connect(update_ship_stats.bind(i))


func create_placeholder_frame(faction: Utility.FACTION) -> void:
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[Utility.SHIP_TYPES.D5_Class]
	var container: Control = Control.new()

	# Create the frame
	var frame: TextureButton = TextureButton.new()
	frame.scale = Vector2(1.3, 1.3)
	frame.name = "Placeholder"

	# Create the ship image
	var ship_image: TextureRect = TextureRect.new()
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = sprite_sheet
	atlas_texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48) # Default value
	ship_image.texture = atlas_texture
	atlas_texture.filter_clip = true
	ship_image.scale = Vector2(1.2, 1.2)
	ship_image.position = Vector2(14, 14)
	
	# Ensure the ship image is behind the frame
	ship_image.z_index = 1
	frame.z_index = -1
	
	# Add the container to the appropriate faction grid
	match faction:
		Utility.FACTION.FEDERATION:
			%FederationGrid.add_child(container)
			frame.texture_normal = federation_frame
			frame.texture_hover = federation_frame_pressed
			container.name = "Fed_Container_Placeholder"
				
		Utility.FACTION.KLINGON:
			%KlingonGrid.add_child(container)
			frame.texture_normal = klingon_frame
			frame.texture_hover = klingon_frame_pressed
			container.name = "Klin_Container_Placeholder"
				
		Utility.FACTION.ROMULAN:
			%RomulanGrid.add_child(container)
			frame.texture_normal = romulan_frame
			frame.texture_hover = romulan_frame_pressed
			container.name = "Rom_Container_Placeholder"
				
		Utility.FACTION.NEUTRAL:
			%NeutralGrid.add_child(container)
			frame.texture_normal = neutral_frame
			frame.texture_hover = neutral_frame_pressed
			container.name = "Neut_Container_Placeholder"
		
	container.add_child(ship_image)
	container.add_child(frame)

	frame.mouse_entered.connect(update_ship_stats.bind("placeholder"))


func update_ship_stats(ship:Variant) -> void:
	if typeof(ship) == TYPE_INT:
		var ship_data:Dictionary = Utility.PLAYER_SHIP_STATS.values()[ship]
		var faction: Utility.FACTION = Utility.SHIP_DATA.values()[ship].FACTION

		%ship_name.text = "Ship Name: " + Utility.UI_ship_lime + ship_data.SHIP_NAME.replace("_", " ")
		%health_stat.text = "Health: " + str(ship_data.MAX_HP)
		%shield_stat.text = "Shield: " + str(ship_data.MAX_SHIELD)
		%weapon.text = "Default Weapon: Torpedo"
		%speed_stat.text = "Max Speed: " + str(ship_data.SPEED)
		%maneuver_stat.text = "Maneuverability: " + str(ship_data.ROTATION_SPEED)
		
		match faction:
			Utility.FACTION.FEDERATION:
				%faction.text = "Faction: " + Utility.fed_blue + str(Utility.FACTION.keys()[Utility.FACTION.FEDERATION]).to_pascal_case()
			Utility.FACTION.KLINGON:
				%faction.text = "Faction: " + Utility.klin_red + str(Utility.FACTION.keys()[Utility.FACTION.KLINGON]).to_pascal_case()
			Utility.FACTION.ROMULAN:
				%faction.text = "Faction: " + Utility.rom_green + str(Utility.FACTION.keys()[Utility.FACTION.ROMULAN]).to_pascal_case()
			Utility.FACTION.NEUTRAL:
				%faction.text = "Faction: " + Utility.neut_cyan + str(Utility.FACTION.keys()[Utility.FACTION.NEUTRAL]).to_pascal_case()
		warp_stat.text = "Warp Range: " + str(ship_data.WARP_RANGE)
	
	elif typeof(ship) == TYPE_STRING:
		%ship_name.text = "Ship Name: Placeholder"
		%faction.text = "Faction: Placeholder"
		%health_stat.text = "Health: Placeholder"
		%shield_stat.text = "Shield: Placeholder"
		%weapon.text = "Default Weapon: Placeholder"
		%speed_stat.text = "Max Speed: Placeholder"
		%maneuver_stat.text = "Maneuverability: Placeholder"
		%warp_stat.text = "Antimatter: Placeholder"


func _on_close_menu_button_pressed() -> void:
	self.visible = false
	menu_state_machine.current_state = menu_state_machine.MenuState.NONE
