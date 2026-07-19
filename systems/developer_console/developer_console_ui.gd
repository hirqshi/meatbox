extends CanvasLayer

@export var console_toggle_key: Key = KEY_QUOTELEFT
@export var max_visible_log_lines: int = 80

@onready var _panel: PanelContainer = %Panel
@onready var _log_output: RichTextLabel = %LogOutput
@onready var _command_input: LineEdit = %CommandInput

var _history: Array[String] = []
var _history_index: int = -1
var _visible_log_lines: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	DeveloperConsole.message_logged.connect(_on_message_logged)
	DeveloperConsole.open_state_changed.connect(_on_open_state_changed)
	_command_input.text_submitted.connect(_on_command_submitted)

	_log_output.fit_content = false
	_log_output.scroll_active = true
	_log_output.scroll_following = true
	_log_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_output.mouse_filter = Control.MOUSE_FILTER_STOP

	_panel.visible = DeveloperConsole.is_open()
	_command_input.keep_editing_on_text_submit = true

	DeveloperConsole.log_info("Console UI connected.")
	

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.is_echo():
		return

	if event.keycode == console_toggle_key:
		DeveloperConsole.toggle_open()
		get_viewport().set_input_as_handled()
		return

	if not DeveloperConsole.is_open():
		return

	if event.keycode == KEY_ESCAPE:
		DeveloperConsole.set_is_open(false)
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_UP:
		_show_previous_command()
		get_viewport().set_input_as_handled()
		return

	if event.keycode == KEY_DOWN:
		_show_next_command()
		get_viewport().set_input_as_handled()


func _on_open_state_changed(is_open: bool) -> void:
	_panel.visible = is_open

	if is_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_command_input.call_deferred("grab_focus")
		return

	_command_input.release_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_command_submitted(command_line: String) -> void:
	DeveloperConsole.execute(command_line)
	_command_input.clear()
	_history = DeveloperConsole.get_history()
	_history_index = _history.size()
	_command_input.grab_focus()


func _on_message_logged(
	message: String,
	level: DeveloperConsole.LogLevel
) -> void:
	var colored_message: String = "[color=%s]%s[/color]" % [
		_get_level_color(level).to_html(false),
		message
	]

	_visible_log_lines.append(colored_message)

	if _visible_log_lines.size() > max_visible_log_lines:
		_visible_log_lines.pop_front()

	_log_output.text = "\n".join(_visible_log_lines)

	var last_line_index: int = _log_output.get_line_count() - 1

	if last_line_index >= 0:
		_log_output.call_deferred("scroll_to_line", last_line_index)


func _show_previous_command() -> void:
	if _history.is_empty():
		return

	_history_index = maxi(_history_index - 1, 0)
	_command_input.text = _history[_history_index]
	_command_input.caret_column = _command_input.text.length()


func _show_next_command() -> void:
	if _history.is_empty():
		return

	_history_index = mini(_history_index + 1, _history.size())

	if _history_index >= _history.size():
		_command_input.clear()
		return

	_command_input.text = _history[_history_index]
	_command_input.caret_column = _command_input.text.length()


func _get_level_color(level: DeveloperConsole.LogLevel) -> Color:
	match level:
		DeveloperConsole.LogLevel.WARNING:
			return Color("f6ca55")
		DeveloperConsole.LogLevel.ERROR:
			return Color("ff6b6b")
		_:
			return Color("d8d8d8")
