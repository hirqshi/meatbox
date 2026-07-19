extends Node

signal time_scale_changed(previous_scale: float, current_scale: float)

var _base_time_scale: float = 1.0
var _active_scales: Dictionary[StringName, float] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_time_scale()


func set_base_time_scale(time_scale: float) -> void:
	_base_time_scale = maxf(time_scale, 0.0)
	_apply_time_scale()


func set_modifier(source_id: StringName, time_scale: float) -> void:
	assert(not source_id.is_empty(), "Time scale source id must not be empty.")

	_active_scales[source_id] = maxf(time_scale, 0.0)
	_apply_time_scale()


func remove_modifier(source_id: StringName) -> void:
	if not _active_scales.erase(source_id):
		return

	_apply_time_scale()


func get_effective_time_scale() -> float:
	var effective_scale: float = _base_time_scale

	for modifier_scale: float in _active_scales.values():
		effective_scale = minf(effective_scale, modifier_scale)

	return effective_scale


func reset() -> void:
	_base_time_scale = 1.0
	_active_scales.clear()
	_apply_time_scale()


func _apply_time_scale() -> void:
	var previous_scale: float = Engine.time_scale
	var next_scale: float = get_effective_time_scale()

	if is_equal_approx(previous_scale, next_scale):
		return

	Engine.time_scale = next_scale
	time_scale_changed.emit(previous_scale, next_scale)
