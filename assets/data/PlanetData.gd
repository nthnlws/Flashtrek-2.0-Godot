extends Resource
class_name PlanetData

@export var name: String
@export var frame: int = 0
@export var world_position: Vector2 = Vector2.ZERO
@export var faction: Utility.FACTION

# Components
var AnalyzeComponent_scene: PackedScene = preload("res://scenes/components/analyze_planet_component.tscn")
var CommunicationComponent_scene: PackedScene = preload("res://scenes/components/planet_communication_component.tscn")

@export var has_AnalyzeComponent: bool = false
@export var has_CommunicationComponent: bool = true

func add_AnalyzeComponent() -> void:
	has_AnalyzeComponent = true

func add_CommunicationComponent() -> void:
	has_CommunicationComponent = true
