extends Node
class_name Hitmarker

enum TargetType { SELF, SHIELD, HULL }
const DAMAGE_MARKER = preload("res://scenes/level_entities/damage_marker.tscn")
@onready var hitmarker_manager: Hitmarker = $"."

static func createDamageHitmarker(damage_value:float, marker_position:Vector2, color:TargetType):
	var node = Engine.get_main_loop().current_scene.get_node("Level/hitmarker_manager")
	var marker:Marker2D = DAMAGE_MARKER.instantiate()
	node.add_child(marker)
	marker.global_position = marker_position
	var text: RichTextLabel = marker.get_child(0)
	
	match color:
		TargetType.SELF:
			text.bbcode_text = Utility.damage_red + str(snapped(damage_value, 0.1))
		TargetType.SHIELD:
			text.bbcode_text = Utility.damage_blue + str(snapped(damage_value, 0.1))
		TargetType.HULL:
			text.bbcode_text = Utility.damage_green + str(snapped(damage_value, 0.1))
