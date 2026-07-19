extends CanvasLayer

@onready var _panel: PanelContainer = $MarginContainer/PanelContainer
@onready var _stats_text: Label = $MarginContainer/PanelContainer/StatsText

var _player: CharacterBody3D
var _health_component: HealthComponent


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	DeveloperConsole.stats_overlay_visibility_changed.connect(
		_on_stats_overlay_visibility_changed
	)

	_panel.visible = DeveloperConsole.is_stats_overlay_visible()


func setup(player: CharacterBody3D) -> void:
	assert(player != null, "DebugStatsOverlay requires a valid player.")

	if is_instance_valid(_player):
		var old_tree_exited_callable: Callable = _on_player_tree_exited

		if _player.tree_exited.is_connected(old_tree_exited_callable):
			_player.tree_exited.disconnect(old_tree_exited_callable)

	_player = player
	_health_component = (
		_player.get_node_or_null("HealthComponent") as HealthComponent
	)

	_player.tree_exited.connect(_on_player_tree_exited)


func _process(_delta: float) -> void:
	if not _panel.visible:
		return

	if not is_instance_valid(_player):
		_stats_text.text = "PLAYER DEBUG\nwaiting for player..."
		return

	_update_stats_text()


func _update_stats_text() -> void:
	var horizontal_speed_mps: float = Vector2(
		_player.velocity.x,
		_player.velocity.z
	).length()

	var health_text: String = "N/A"

	if is_instance_valid(_health_component):
		health_text = "%.1f / %.1f" % [
			_health_component.get_current_health(),
			_health_component.get_max_health(),
		]

	_stats_text.text = (
		"PLAYER DEBUG\n"
		+ "Position: %.2f, %.2f, %.2f\n"
		% [
			_player.global_position.x,
			_player.global_position.y,
			_player.global_position.z,
		]
		+ "Velocity: %.2f, %.2f, %.2f\n"
		% [
			_player.velocity.x,
			_player.velocity.y,
			_player.velocity.z,
		]
		+ "Horizontal speed: %.2f m/s\n"
		% horizontal_speed_mps
		+ "Health: %s\n"
		% health_text
		+ "On floor: %s\n"
		% _player.is_on_floor()
		+ "Console: %s"
		% ("open" if DeveloperConsole.is_open() else "closed")
	)


func _on_stats_overlay_visibility_changed(is_visible: bool) -> void:
	_panel.visible = is_visible


func _on_player_tree_exited() -> void:
	_player = null
	_health_component = null
