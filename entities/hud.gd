extends Control

onready var health_bar = $MC/VBC/HealthBar
onready var laser_timer = $MC/VBC/HBC/LaserTimer
onready var bouncing_bullet_timer = $MC/VBC/HBC/BouncingBulletTimer
onready var score_label = $MC1/Score


func _ready() -> void:
	EventBus.connect("asteroid_destroyed", self, "_on_asteroid_destroyed")
	EventBus.connect("ufo_destroyed", self, "_on_ufo_destroyed")
	HighScoreManager.current_score = 0


func update_score(value: int) -> void:
	score_label.text = str(value)


func update_health_bar(new_hp: int) -> void:
	health_bar.update(new_hp)


func update_laser_timer(value: float = 0.0) -> void:
	laser_timer.update(value)


func update_bouncing_bullet_timer(value: float = 0.0) -> void:
	bouncing_bullet_timer.update(value)


func _on_asteroid_destroyed(value: int = 0) -> void:
	HighScoreManager.current_score += value
	update_score(HighScoreManager.current_score)


func _on_ufo_destroyed(value: int = 0) -> void:
	HighScoreManager.current_score += value
	update_score(HighScoreManager.current_score)
