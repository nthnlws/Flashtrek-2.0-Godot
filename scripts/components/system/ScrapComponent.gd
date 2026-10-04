class_name ScrapComponent
extends SystemComponent

const SCRAP_TEXTURE: Texture2D = preload("uid://bmybeo1pjo21w")
## Visual size of each pile: scales piece sprites and their offsets within the
## pile. Pile anchors and the field center are unaffected.
const PILE_SCALE: float = 2.0
## Read by the minimap (debug builds only) - one white marker per field.
const MINIMAP_GROUP: StringName = &"minimap_scrap_marker"

var component_data: ScrapComponentData


func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as ScrapComponentData
	position = component_data.field_center
	add_to_group(MINIMAP_GROUP)
	spawn_scrap()


func spawn_scrap() -> void:
	for pile_index: int in range(component_data.component_scrap_piles.size()):
		var pile: ScrapPileConfig = component_data.component_scrap_piles[pile_index]
		var base_position: Vector2 = component_data.get_pile_position(pile_index)
		for i: int in range(pile.positions.size()):
			var piece_position: Vector2 = base_position + pile.positions[i] * PILE_SCALE
			var piece: Node2D = _create_piece(Vector2i(pile_index, i), pile.regions[i])
			if piece == null:
				continue
			piece.position = piece_position
			piece.rotation = pile.rotations[i]
			piece.scale = Vector2.ONE * PILE_SCALE
			add_child(piece)


## Override to replace pieces. Returning null skips the piece.
func _create_piece(_key: Vector2i, region: Rect2) -> Node2D:
	var sprite := Sprite2D.new()
	sprite.texture = SCRAP_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = region
	return sprite
