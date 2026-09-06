extends Node2D
class_name ShipStatusBar

@export var health_component: HealthComponent
@export var energy_component: EnergyComponent

@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var shield_bar: ProgressBar = $VBoxContainer/ShieldBar
@onready var energy_bar: ProgressBar = $VBoxContainer/EnergyBar


func _process(delta: float) -> void:
	if global_rotation != 0:
		global_rotation = 0


func _ready() -> void:
	SignalBus.healthBoxesDebugToggle.connect(toggle_health_boxes)
	SignalBus.energyBoxesDebugToggle.connect(toggle_energy_boxes)
	
	if health_component:
		health_component.health_changed.connect(update_healthbar_current)
		health_component.shield_changed.connect(update_shieldbar_current)
		health_component.health_max_changed.connect(update_healthbar_max)
		health_component.shield_max_changed.connect(update_shieldbar_max)
	
	if energy_component:
		energy_component.max_energy_changed.connect(update_energybar_max)
		energy_component.energy_changed.connect(update_energybar_current)
	else: energy_bar.queue_free()


func update_healthbar_current(new_value):
	health_bar.value = new_value

func update_healthbar_max(new_value):
	health_bar.max_value = new_value

func update_shieldbar_current(new_value):
	shield_bar.value = new_value

func update_shieldbar_max(new_value):
	shield_bar.max_value = new_value

func update_energybar_max(new_value):
	energy_bar.max_value = new_value

func update_energybar_current(new_value):
	energy_bar.value = new_value


func toggle_health_boxes(new_state:bool) -> void:
	if health_bar:
		health_bar.visible = new_state
	if shield_bar:
		shield_bar.visible = new_state

func toggle_energy_boxes(new_state:bool) -> void:
	if energy_bar:
		energy_bar.visible = new_state
