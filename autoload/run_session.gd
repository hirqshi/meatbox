extends Node

signal run_started(config: RunConfig)
signal floor_changed(floor_index: int)
signal run_ended()

var _config: RunConfig
var _random: RunRandom
var _current_floor_index: int = 0
var _is_run_active: bool = false


func start_run(config: RunConfig) -> void:
	assert(config != null, "RunSession requires a valid RunConfig.")

	_config = config
	_random = RunRandom.new(config.run_seed)
	_current_floor_index = config.starting_floor_index
	_is_run_active = true

	run_started.emit(_config)
	floor_changed.emit(_current_floor_index)


func end_run() -> void:
	if not _is_run_active:
		return

	_is_run_active = false
	run_ended.emit()

	_config = null
	_random = null
	_current_floor_index = 0


func get_config() -> RunConfig:
	return _config


func get_random() -> RunRandom:
	return _random


func get_current_floor_index() -> int:
	return _current_floor_index


func is_run_active() -> bool:
	return _is_run_active


func set_current_floor_index(floor_index: int) -> void:
	assert(floor_index > 0, "Floor index must be greater than zero.")

	_current_floor_index = floor_index
	floor_changed.emit(_current_floor_index)
