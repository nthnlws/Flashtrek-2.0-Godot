extends Node2D
class_name Planet

@onready var label: RichTextLabel = $Label
@onready var sprite: Sprite2D = $PlanetTexture
@onready var components: Node2D = $Components

var planet_data: PlanetData
var planetFaction: Utility.FACTION = Utility.FACTION.FEDERATION
var CanCommunicate: bool = false
var player: Player
var player_in_mission_area: bool = false

@export var communication_component: PlanetCommunicationComponent
@export var analyze_planet_component: AnalyzePlanetComponent


func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(fade_label.bind("off"))
	SignalBus.entering_new_system.connect(fade_label.bind("on"))
	
	sync_planet_to_data()
	sync_components()
	
	var random_index: int = randi_range(0, 220)
	sprite.frame = random_index
	z_index = Utility.Z["Planets"]

func sync_planet_to_data() -> void:
	self.global_position = planet_data.world_position
	self.set_frame(planet_data.frame)
	self.name = planet_data.name
	self.set_label(planet_data.name)
	self.planetFaction = planet_data.faction


func sync_components() -> void:
	if planet_data.has_AnalyzeComponent:
		var new_component:Node = planet_data.AnalyzeComponent_scene.instantiate()
		components.add_child(new_component)
		analyze_planet_component = new_component
	if planet_data.has_CommunicationComponent:
		var new_component:Node = planet_data.CommunicationComponent_scene.instantiate()
		components.add_child(new_component)
		communication_component = new_component


func _physics_process(delta: float) -> void:
	sprite.rotate(deg_to_rad(1.5) * delta) # Spin planet


func _on_comm_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.enteredPlanetComm.emit(self)
		SignalBus.toggleQ3HUD.emit("on")
		player = body


func _on_comm_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.exitedPlanetComm.emit(self)
		SignalBus.toggleQ3HUD.emit("off")
		player = null


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
