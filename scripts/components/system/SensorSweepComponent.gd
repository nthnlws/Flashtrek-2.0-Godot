class_name SensorSweepComponent
extends SystemComponent

const MISSION_INDICATOR = preload("uid://cj1a8ynj87xoc")
const SCAN_TIME: float = 2.5
const TIME_WARNINGS: Array[float] = [30.0, 10.0]

var component_data: SensorSweepComponentData

## Buoy position -> MissionIndicator.
var indicators: Dictionary = {}
var _active_point: Variant = null
var _scan_progress: float = 0.0


func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as SensorSweepComponentData
	if component_data.scan_points.is_empty():
		complete(component_data)
		return

	for point: Vector2 in component_data.scan_points:
		var indicator: MissionIndicator = MISSION_INDICATOR.instantiate()
		add_child(indicator)
		indicator.scale = Vector2(3.0, 3.0)
		indicator.activate_indicator(point)
		indicator.player_entered.connect(_on_player_entered.bind(point))
		indicator.player_exited.connect(_on_player_exited.bind(point))
		indicators[point] = indicator

	SignalBus.changePopMessage.emit("Sensor sweep: %d buoys, %s remaining" % [component_data.scan_points.size(), _format_time(component_data.time_remaining)])


func _physics_process(delta: float) -> void:
	if component_data.is_finished or Utility.current_gamestate != Utility.GAMESTATE.SYSTEM:
		return

	var previous: float = component_data.time_remaining
	component_data.time_remaining -= delta
	for warning: float in TIME_WARNINGS:
		if previous > warning and component_data.time_remaining <= warning:
			SignalBus.changePopMessage.emit("Survey window closing - %d seconds left" % int(warning))
	if component_data.time_remaining <= 0.0:
		fail(component_data, "The survey window closed - mission failed")
		return

	if _active_point == null:
		return
	_scan_progress += delta
	if _scan_progress >= SCAN_TIME:
		_calibrate(_active_point)


func _on_player_entered(_body: Node2D, point: Vector2) -> void:
	_active_point = point
	_scan_progress = 0.0


func _on_player_exited(_body: Node2D, point: Vector2) -> void:
	if _active_point == point:
		_active_point = null
		_scan_progress = 0.0


func _calibrate(point: Vector2) -> void:
	_active_point = null
	_scan_progress = 0.0
	component_data.scan_points.erase(point)
	if indicators.has(point):
		indicators[point].queue_free()
		indicators.erase(point)

	if component_data.scan_points.is_empty():
		complete(component_data)
	else:
		SignalBus.changePopMessage.emit("Buoy calibrated - %d remaining" % component_data.scan_points.size())
		MissionManager.report_progress(component_data.mission_id, component_data.scan_points.size())


static func _format_time(seconds: float) -> String:
	var total: int = maxi(int(seconds), 0)
	return "%d:%02d" % [total / 60, total % 60]
