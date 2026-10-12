extends Weapon
class_name MissileLauncher
## Secondary weapon. Click to launch a homing missile that winds toward the
## clicked point and explodes there (area damage with falloff).

@export var projectile_scene: PackedScene = preload("uid://dj5rx83i8si03") # homing_missile.tscn
@export var regen_lock_seconds: float = 1.0

@onready var fire_sound: AudioStreamPlayer2D = $FireSound


func use(pressed: bool) -> void:
	if pressed and data and is_ready() and slot and slot.can_use():
		try_fire(get_global_mouse_position())


## Returns true if a missile was launched.
func try_fire(target_position: Vector2) -> bool:
	if not slot.spend_energy(data.energy_cost, regen_lock_seconds):
		return false

	var missile: HomingMissile = projectile_scene.instantiate()
	missile.global_position = global_position
	missile.rotation = slot.ship.rotation
	missile.target_position = target_position
	# Damage = data.damage * falloff * multiplier (multiplier applied once, in HomingMissile)
	missile.max_damage = data.damage
	missile.damage_multipler = slot.get_damage_mult()
	slot.prepare_projectile(missile)
	slot.spawn_projectile(missile)

	fire_sound.pitch_scale = randf_range(0.95, 1.05)
	fire_sound.play()
	start_cooldown()
	return true
