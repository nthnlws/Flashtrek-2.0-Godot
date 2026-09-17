class_name ScrapComponent
extends SystemComponent

const SCRAP_TEXTURE: Texture2D = preload("uid://bmybeo1pjo21w")

var component_data: ScrapComponentData


func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as ScrapComponentData
	spawn_scrap()


func spawn_scrap() -> void:
	for pile: ScrapPileConfig in component_data.component_scrap_piles:
		var base_position: Vector2 = Utility.get_random_point_on_circle(1500)
		for i: int in range(pile.positions.size()):
			var sprite := Sprite2D.new()
			sprite.texture = SCRAP_TEXTURE
			sprite.region_enabled = true
			sprite.region_rect = pile.regions[i]

			sprite.position = base_position + pile.positions[i]
			sprite.rotation = pile.rotations[i]

			add_child(sprite)
