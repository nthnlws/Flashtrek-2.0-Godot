extends Node2D
class_name Planet

@onready var label: RichTextLabel = $Label
@onready var sprite: Sprite2D = $PlanetTexture
@onready var component_manager: Node = $PlanetComponentManager

var planet_data: PlanetData
var planetFaction: Utility.FACTION = Utility.FACTION.FEDERATION
var CanCommunicate: bool = false
var player_in_mission_area: bool = false


func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(fade_label.bind("off"))
	SignalBus.entering_new_system.connect(fade_label.bind("on"))
	
	sync_planet_to_data()
	#TODO emit Planet _ready signal
	
	var random_index: int = randi_range(0, 220)
	sprite.frame = random_index
	z_index = Utility.Z["Planets"]


func sync_planet_to_data() -> void:
	self.global_position = planet_data.world_position
	self.set_frame(planet_data.frame)
	self.name = planet_data.name
	self.set_label(planet_data.name)
	self.planetFaction = planet_data.faction
	
	component_manager.sync_components(planet_data)


func _physics_process(delta: float) -> void:
	sprite.rotate(deg_to_rad(1.5) * delta) # Spin planet



func set_frame(index: int) -> void:
	sprite.frame = index


func set_label(planet_name: String) -> void:
	self.name = planet_name # Ensure node name matches
	label.text = Utility.UI_blue + planet_name # 'text' handles bbcode if enabled


func fade_label(state: String) -> void:
	if state == "off":
		create_tween().tween_property(label, "modulate", Color(1, 1, 1, 0), Utility.fadeLength)
	elif state == "on":
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(label, "modulate", Color(1, 1, 1, 1), Utility.fadeLength)

func attempt_interaction(ship_name: String) -> String:
	if component_manager.has_component_type(&"communication"):
		var comm_component = component_manager.get_component_by_type(&"communication")
		if is_instance_valid(comm_component) and comm_component.has_method("attempt_interaction"):
			return comm_component.attempt_interaction(ship_name)
	return ""
