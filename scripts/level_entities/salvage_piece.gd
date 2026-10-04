## Tractor-beam pickup built by SalvageComponent.
class_name SalvagePiece
extends Area2D

signal collected(piece: SalvagePiece)

const INTERACTABLE_LAYER: int = 512
const HIGHLIGHT: Color = Color(0.55, 1.0, 0.75)

var salvage_key: Vector2i


static func create(texture: Texture2D, region: Rect2, key: Vector2i) -> SalvagePiece:
	var piece: SalvagePiece = SalvagePiece.new()
	piece.salvage_key = key
	piece.collision_layer = INTERACTABLE_LAYER
	piece.collision_mask = 0

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	piece.add_child(sprite)

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = maxf(region.size.x, region.size.y) * 0.5
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	piece.add_child(collision)
	return piece


func _ready() -> void:
	z_index = Utility.Z["LootDrops"]
	add_to_group(MissionManager.MINIMAP_MARKER_GROUP)
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(self, "modulate", HIGHLIGHT, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_SINE)


## Tractor beam pickup interface.
func collect_pickup() -> void:
	collected.emit(self)
	queue_free()
