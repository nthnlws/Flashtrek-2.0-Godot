# galaxy_editor.gd
@tool
extends Control

var neighbor_map: Dictionary = {
	"Solarus": ["6", "7", "8", "10"],
	"Kronos": ["16", "17", "18", "20", "21"],
	"Romulus": ["26", "29", "30", "31"],
	"1": ["2", "3"],
	"2": ["1", "4"],
	"3": ["1", "5"],
	"4": ["2", "15", "6"],
	"5": ["3", "6", "7"],
	"6": ["4", "11", "Solarus", "5"],
	"7": ["5", "Solarus", "8"],
	"8": ["7", "Solarus", "9"],
	"9": ["8", "10"],
	"10": ["9", "Solarus", "11"],
	"11": ["6", "12", "10"],
	"12": ["11", "13", "19", "28"],
	"13": ["14", "12"],
	"14": ["18", "13"],
	"15": ["4", "16"],
	"16": ["15", "17", "Kronos"],
	"17": ["16", "Kronos"],
	"18": ["14", "Kronos", "20", "19"],
	"19": ["12", "18", "20", "27"],
	"20": ["19", "18", "Kronos", "28"],
	"21": ["Kronos", "22", "24"],
	"22": ["21", "23"],
	"23": ["22", "24"],
	"24": ["21", "23", "25"],
	"25": ["24", "30"],
	"26": ["29", "27", "20", "24", "Romulus"],
	"27": ["19", "26", "28"],
	"28": ["27", "29"],
	"29": ["28", "26", "Romulus"],
	"30": ["Romulus", "25", "31"],
	"31": ["Romulus", "30"],
}

@export_file("*.tres") var output_file_path: String = "res://assets/data/galaxy_map.tres"

@export var generate_button := false: set = _on_generate_button_pressed

func _on_generate_button_pressed(value) -> void:
	if value:
		generate_button = false  # Reset the button toggle after press
		generate_galaxy_map()


func _ready() -> void:
	if Engine.is_editor_hint():
		print("GalaxyEditor ready in editor.")


func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("tool_script"):
		generate_galaxy_map()


func generate_galaxy_map() -> void:
	var GalaxyMap := preload("res://assets/data/GalaxyMap.gd")
	var SystemData := preload("res://assets/data/SystemData.gd")
	var new_map = GalaxyMap.new()
	
	# First pass: collect all systems and store by name for easy lookup
	var systems_dict: Dictionary = {}
	
	for child in get_children():
		if not child is Marker2D:
			continue
	
		var data = SystemData.new()
		data.system_name = child.name
		data.position = child.position
		systems_dict[child.name] = data

	# Second pass: assign neighbors
	for name in systems_dict:
		var system = systems_dict[name]
		system.neighbors = neighbor_map.get(name, [])
		new_map.systems.append(system)

	ResourceSaver.save(new_map, output_file_path)
	print("Galaxy map saved to ", output_file_path)
