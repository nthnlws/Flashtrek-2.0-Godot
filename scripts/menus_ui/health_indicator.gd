extends Control
class_name HealthIndicator

@onready var shield_icon: ColorRect = $shield_icon
@onready var hull_icon: TextureRect = $hull_icon
@onready var energy_bar: CustomProgressBar = $energy_bar


func _ready() -> void:
	SignalBus.entering_galaxy_warp.connect(fade_indicator.bind("off"))
	SignalBus.entering_new_system.connect(fade_indicator.bind("on"))
	SignalBus.player_type_changed.connect(change_health_sprite)
	
	hull_icon.update_sprite_position()
	set_bar_position(shield_icon.size.x * shield_icon.scale.x, shield_icon.size.y * shield_icon.scale.y)
	
	
func change_health_sprite(ship:Utility.SHIP_TYPES):
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[ship]
	hull_icon.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
	shield_icon.scale = Vector2(ship_data.SHIELD_SCALE_X * 1.87, ship_data.SHIELD_SCALE_Y * 1.87)
	
	hull_icon.initialize_hull_icon()
	hull_icon.calculate_and_set_content_bounds()
	hull_icon.update_hud_health_display()
	hull_icon.update_sprite_position()
	set_bar_position(shield_icon.get_rect().size.x, shield_icon.get_rect().size.y)


func fade_indicator(state) -> void:
	if state == "off":
		create_tween().tween_property(self, "modulate", Color(1, 1, 1, 0), Utility.fadeLength)
	else:
		var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(self, "modulate", Color(1, 1, 1, 1), Utility.fadeLength)


func set_bar_position(x: float, y: float):
	energy_bar.custom_minimum_size = Vector2(y, 20.0)
	energy_bar.size = Vector2(y, 20.0)
	energy_bar.position = Vector2(x, 60.0)


func update_shield_health(new_SP:float) -> void:
	shield_icon.current_SP = new_SP


func update_hitbox_health(new_HP:float) -> void:
	hull_icon.current_HP = new_HP


func update_hitbox_max(new_max_HP:float) -> void:
	hull_icon.max_HP = new_max_HP


func update_shield_max(new_max_HP:float) -> void:
	shield_icon.max_SP = new_max_HP


func update_energy_max(new_max_energy:float) -> void:
	energy_bar.set_max_value(new_max_energy)


func update_energy_value(new_energy:float) -> void:
	energy_bar.set_bar_value(new_energy)
