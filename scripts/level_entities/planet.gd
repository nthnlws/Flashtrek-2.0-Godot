extends Node2D

@onready var node: Node2D = $Node
@onready var label: RichTextLabel = $Node/Label
@onready var sprite: Sprite2D = $PlanetTexture

var planetFaction: Utility.FACTION = Utility.FACTION.FEDERATION

var CanCommunicate: bool = false
var player: Player


func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(fade_label.bind("off"))
	SignalBus.entering_new_system.connect(fade_label.bind("on"))
	
	var random_index: int = randi_range(0, 220)
	sprite.frame = random_index
	z_index = Utility.Z["Planets"]
	
	Utility.mainScene.planets.append(self)


func _physics_process(delta: float) -> void:
	rotate(deg_to_rad(1.5)*delta)
	node.global_rotation = 0 # Counter rotate label


func _on_comm_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.enteredPlanetComm.emit(self)


func _on_comm_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.exitedPlanetComm.emit(self)


func set_label(planet_name: String) -> void:
	label.bbcode_text = Utility.UI_blue + planet_name


func fade_label(state) -> void:
	if state == "off":
		create_tween().tween_property(label, "modulate", Color(1, 1, 1, 0), Utility.fadeLength)
	elif state == "on":
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(label, "modulate", Color(1, 1, 1, 1), Utility.fadeLength)
