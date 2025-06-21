extends Control

@onready var sp_health: ColorRect = $SP_health
@onready var hp_health: TextureRect = $HP_health

func _ready() -> void:
	SignalBus.player_type_changed.connect(change_health_sprite)


func change_health_sprite(ship:Utility.SHIP_TYPES):
	var ship_data:Dictionary = Utility.SHIP_DATA.values()[ship]
	hp_health.texture.region = Rect2(ship_data.SPRITE_X, ship_data.SPRITE_Y, 48, 48)
	hp_health.update_hud_health_display()
	hp_health._calculate_and_set_content_bounds()
	
func update_shield_health(new_SP) -> void:
	sp_health.current_SP = new_SP


func update_hitbox_health(new_HP) -> void:
	hp_health.current_HP = new_HP


func update_hitbox_max(mew_max_HP) -> void:
	hp_health.max_HP = mew_max_HP


func update_shield_max(mew_max_SP) -> void:
	sp_health.max_SP = mew_max_SP
