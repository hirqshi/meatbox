extends Node

signal message_logged(message: String, level: LogLevel)
signal command_executed(command_line: String)

enum LogLevel {
	INFO,
	WARNING,
	ERROR,
}

var _is_open: bool = false
var _history: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func set_is_open(value: bool) -> void:
	_is_open = value


func is_open() -> bool:
	return _is_open


func log_info(message: String) -> void:
	_log(message, LogLevel.INFO)


func log_warning(message: String) -> void:
	_log(message, LogLevel.WARNING)


func log_error(message: String) -> void:
	_log(message, LogLevel.ERROR)


func execute(command_line: String) -> void:
	var normalized_command: String = command_line.strip_edges()

	if normalized_command.is_empty():
		return

	_history.append(normalized_command)
	command_executed.emit(normalized_command)
	log_info("> %s" % normalized_command)


func get_history() -> Array[String]:
	return _history.duplicate()


func _log(message: String, level: LogLevel) -> void:
	var level_name: String = _get_level_name(level)
	var formatted_message: String = "[%s] %s" % [level_name, message]

	print_debug(formatted_message)
	message_logged.emit(formatted_message, level)

func _get_level_name(level: LogLevel) -> String:
	match level:
		LogLevel.INFO:
			return "INFO"
		LogLevel.WARNING:
			return "WARNING"
		LogLevel.ERROR:
			return "ERROR"

	return "UNKNOWN"
