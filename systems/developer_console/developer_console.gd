extends Node

signal message_logged(message: String, level: LogLevel)
signal command_executed(command_line: String)
signal open_state_changed(is_open: bool)
signal stats_overlay_visibility_changed(is_visible: bool)

enum LogLevel {
	INFO,
	WARNING,
	ERROR,
}

const MAX_HISTORY_SIZE: int = 100

var _is_open: bool = false
var _is_stats_overlay_visible: bool = false
var _history: Array[String] = []
var _commands: Dictionary[StringName, Callable] = {}
var _command_descriptions: Dictionary[StringName, String] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_builtin_commands()

	log_info("Developer console ready. Type 'help' for commands.")


func set_is_open(value: bool) -> void:
	if _is_open == value:
		return

	_is_open = value
	open_state_changed.emit(_is_open)


func is_open() -> bool:
	return _is_open


func toggle_open() -> void:
	set_is_open(not _is_open)


func set_stats_overlay_visible(value: bool) -> void:
	if _is_stats_overlay_visible == value:
		return

	_is_stats_overlay_visible = value
	stats_overlay_visibility_changed.emit(_is_stats_overlay_visible)


func is_stats_overlay_visible() -> bool:
	return _is_stats_overlay_visible


func register_command(
	command_name: StringName,
	description: String,
	callback: Callable
) -> void:
	assert(not command_name.is_empty(), "Console command name cannot be empty.")
	assert(callback.is_valid(), "Console command callback must be valid.")

	if _commands.has(command_name):
		log_warning("Console command '%s' was replaced." % command_name)

	_commands[command_name] = callback
	_command_descriptions[command_name] = description


func unregister_command(
	command_name: StringName,
	expected_callback: Callable
) -> void:
	if not _commands.has(command_name):
		return

	var registered_callback: Callable = _commands[command_name]

	if registered_callback != expected_callback:
		return

	_commands.erase(command_name)
	_command_descriptions.erase(command_name)


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

	_add_history(normalized_command)
	command_executed.emit(normalized_command)
	log_info("> %s" % normalized_command)

	var tokens: PackedStringArray = normalized_command.split(" ", false)
	var command_name: StringName = StringName(tokens[0].to_lower())
	var arguments: PackedStringArray = tokens.slice(1)

	if not _commands.has(command_name):
		log_error(
			"Unknown command '%s'. Type 'help' for commands."
			% command_name
		)
		return

	var callback: Callable = _commands[command_name]

	if callback.get_argument_count() == 0:
		callback.call()
		return

	callback.call(arguments)


func get_history() -> Array[String]:
	return _history.duplicate()


func get_command_descriptions() -> Dictionary[StringName, String]:
	return _command_descriptions.duplicate()


func _register_builtin_commands() -> void:
	register_command(
		&"help",
		"Lists all available commands.",
		_print_help
	)
	register_command(
		&"stats",
		"Shows debug stats overlay state.",
		_print_stats_state
	)
	register_command(
		&"stats_overlay",
		"Usage: stats_overlay [on|off|toggle].",
		_set_stats_overlay
	)


func _print_help() -> void:
	var command_names: Array[StringName] = []

	for command_name: StringName in _command_descriptions:
		command_names.append(command_name)

	command_names.sort()

	for command_name: StringName in command_names:
		log_info(
			"%s - %s"
			% [command_name, _command_descriptions[command_name]]
		)


func _print_stats_state() -> void:
	var state_name: String = (
		"enabled"
		if _is_stats_overlay_visible
		else "disabled"
	)

	log_info("Stats overlay is %s." % state_name)


func _set_stats_overlay(arguments: PackedStringArray) -> void:
	if arguments.is_empty():
		set_stats_overlay_visible(not _is_stats_overlay_visible)
		return

	if arguments.size() != 1:
		log_error("Usage: stats_overlay [on|off|toggle].")
		return

	var value: String = arguments[0].to_lower()

	match value:
		"on":
			set_stats_overlay_visible(true)
		"off":
			set_stats_overlay_visible(false)
		"toggle":
			set_stats_overlay_visible(not _is_stats_overlay_visible)
		_:
			log_error("Usage: stats_overlay [on|off|toggle].")


func _add_history(command: String) -> void:
	_history.append(command)

	if _history.size() > MAX_HISTORY_SIZE:
		_history.pop_front()


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
