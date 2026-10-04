## Salvage mission debris field. Spawns its own pieces - no longer shares
## ScrapComponent's rendering.
class_name SalvageComponent
extends SystemComponent

const SCRAP_TEXTURE: Texture2D = preload("uid://bmybeo1pjo21w")

var salvage_data: SalvageComponentData


func initialize_system_component(data: SystemComponentData) -> void:
	salvage_data = data as SalvageComponentData
	position = salvage_data.field_center
	_spawn_pieces()
	SignalBus.CommsButton_clicked.connect(_on_comms_clicked)
	if salvage_data.remaining_salvage.is_empty():
		MissionManager.mark_ready_for_turn_in(salvage_data.mission_id)


func _spawn_pieces() -> void:
	for pile_index: int in range(salvage_data.component_scrap_piles.size()):
		var pile: ScrapPileConfig = salvage_data.component_scrap_piles[pile_index]
		var base_position: Vector2 = salvage_data.get_pile_position(pile_index)
		for i: int in range(pile.positions.size()):
			var piece: Node2D = _create_piece(Vector2i(pile_index, i), pile.regions[i])
			if piece == null:
				continue
			piece.position = base_position + pile.positions[i]
			piece.rotation = pile.rotations[i]
			add_child(piece)


## Collected pieces are skipped, salvage targets are collectible, the rest is
## plain debris.
func _create_piece(key: Vector2i, region: Rect2) -> Node2D:
	if salvage_data.collected_salvage.has(key):
		return null
	if salvage_data.remaining_salvage.has(key):
		var salvage_piece: SalvagePiece = SalvagePiece.create(SCRAP_TEXTURE, region, key)
		salvage_piece.collected.connect(_on_piece_collected)
		return salvage_piece

	var sprite := Sprite2D.new()
	sprite.texture = SCRAP_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = region
	return sprite


func _on_piece_collected(piece: SalvagePiece) -> void:
	salvage_data.remaining_salvage.erase(piece.salvage_key)
	salvage_data.collected_salvage.append(piece.salvage_key)

	var recovered: int = salvage_data.total_salvage - salvage_data.remaining_salvage.size()
	SignalBus.changePopMessage.emit("Salvage recovered (%d/%d)" % [recovered, salvage_data.total_salvage])

	if salvage_data.remaining_salvage.is_empty():
		MissionManager.mark_ready_for_turn_in(salvage_data.mission_id)
	else:
		MissionManager.report_progress(salvage_data.mission_id, salvage_data.remaining_salvage.size())


## Turn-in: opening comms at the starbase completes the mission, which
## despawns this node and the leftover debris with it.
func _on_comms_clicked() -> void:
	if salvage_data.is_finished or not salvage_data.remaining_salvage.is_empty():
		return
	if LevelManager.starbases.is_empty() or not LevelManager.starbases.front().player_in_range:
		return
	complete(salvage_data)


func _exit_tree() -> void:
	if SignalBus.CommsButton_clicked.is_connected(_on_comms_clicked):
		SignalBus.CommsButton_clicked.disconnect(_on_comms_clicked)
