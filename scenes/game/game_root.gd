extends Node

const PLAYER_SCENE: PackedScene = preload("res://gameplay/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://gameplay/enemies/enemy.tscn")

@export var enemy_spawn_position: Vector3 = Vector3(0.0, 1.0, -10.0)
@export var default_run_config: RunConfig
@export var player_spawn_position: Vector3 = Vector3(0.0, 3.0, 0.0)

@onready var _gameplay_root: Node = $GameplayRoot

var _player: CharacterBody3D
var _active_enemies: Array[Enemy] = []


func _ready() -> void:
	assert(default_run_config != null, "GameRoot requires a default RunConfig.")

	DeveloperConsole.log_info(
		"GameRoot ready. Seed: %d" % default_run_config.run_seed
	)

	if not RunSession.is_run_active():
		RunSession.start_run(default_run_config)

	_player = _spawn_player()
	_setup_player_debug(_player)
	_register_debug_commands()


func _exit_tree() -> void:
	_unregister_debug_commands()


func _register_debug_commands() -> void:
	DeveloperConsole.register_command(
		&"damage_player",
		"Usage: damage_player <amount>.",
		_damage_player_from_console
	)
	DeveloperConsole.register_command(
		&"heal_player",
		"Usage: heal_player <amount|full>.",
		_heal_player_from_console
	)
	DeveloperConsole.register_command(
		&"kill_player",
		"Usage: kill_player.",
		_kill_player_from_console
	)
	DeveloperConsole.register_command(
		&"respawn_player",
		"Usage: respawn_player. Recreates player and clears enemies.",
		_respawn_player_from_console
	)
	DeveloperConsole.register_command(
		&"spawn_enemy",
		"Usage: spawn_enemy. Spawns a test enemy.",
		_spawn_enemy_from_console
	)
	DeveloperConsole.register_command(
		&"clear_enemies",
		"Usage: clear_enemies. Removes all active enemies.",
		_clear_enemies_from_console
	)


func _unregister_debug_commands() -> void:
	DeveloperConsole.unregister_command(
		&"damage_player",
		_damage_player_from_console
	)
	DeveloperConsole.unregister_command(
		&"heal_player",
		_heal_player_from_console
	)
	DeveloperConsole.unregister_command(
		&"kill_player",
		_kill_player_from_console
	)
	DeveloperConsole.unregister_command(
		&"respawn_player",
		_respawn_player_from_console
	)
	DeveloperConsole.unregister_command(
		&"spawn_enemy",
		_spawn_enemy_from_console
	)
	DeveloperConsole.unregister_command(
		&"clear_enemies",
		_clear_enemies_from_console
	)


func _spawn_player() -> CharacterBody3D:
	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D

	assert(player != null, "Player scene root must inherit CharacterBody3D.")

	_gameplay_root.add_child(player)
	player.global_position = player_spawn_position

	return player


func _setup_player_debug(player: CharacterBody3D) -> void:
	DebugStatsOverlay.setup(player)


func _damage_player_from_console(arguments: PackedStringArray) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error("Usage: damage_player <amount>.")
		return

	var amount: float = _parse_positive_amount(arguments[0], "Damage amount")

	if amount <= 0.0:
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	player.apply_debug_damage(amount)
	DeveloperConsole.log_info(
		"Applied %.1f debug damage to player."
		% amount
	)


func _heal_player_from_console(arguments: PackedStringArray) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error("Usage: heal_player <amount|full>.")
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var value: String = arguments[0].to_lower()

	if value == "full":
		player.restore_full_debug_health()
		DeveloperConsole.log_info("Restored player health to full.")
		return

	var amount: float = _parse_positive_amount(value, "Heal amount")

	if amount <= 0.0:
		return

	var restored_health: float = player.restore_debug_health(amount)

	DeveloperConsole.log_info(
		"Restored %.1f player health."
		% restored_health
	)


func _kill_player_from_console(arguments: PackedStringArray) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: kill_player.")
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	player.kill_for_debug()
	DeveloperConsole.log_info("Killed player with debug damage.")


func _respawn_player_from_console(arguments: PackedStringArray) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: respawn_player.")
		return

	_clear_active_enemies()

	if is_instance_valid(_player):
		_player.queue_free()

	_player = _spawn_player()
	_setup_player_debug(_player)

	DeveloperConsole.log_info(
		"Respawned player at %.1f, %.1f, %.1f."
		% [
			_player.global_position.x,
			_player.global_position.y,
			_player.global_position.z,
		]
	)


func _spawn_enemy_from_console(arguments: PackedStringArray) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: spawn_enemy.")
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var enemy: Enemy = _spawn_enemy(player)

	DeveloperConsole.log_info(
		"Spawned %s at %.1f, %.1f, %.1f."
		% [
			enemy.definition.display_name,
			enemy.global_position.x,
			enemy.global_position.y,
			enemy.global_position.z,
		]
	)


func _clear_enemies_from_console(arguments: PackedStringArray) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: clear_enemies.")
		return

	var removed_count: int = _active_enemies.size()

	_clear_active_enemies()

	DeveloperConsole.log_info(
		"Cleared %d enemies."
		% removed_count
	)


func _spawn_enemy(target_player: CharacterBody3D) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy

	assert(enemy != null, "Enemy scene root must inherit CharacterBody3D.")

	_gameplay_root.add_child(enemy)
	enemy.global_position = enemy_spawn_position

	var target_damageable: Damageable = (
		target_player.get_node_or_null("HealthComponent") as Damageable
	)
	assert(target_damageable != null, "Player requires a HealthComponent.")

	enemy.setup_target(target_player, target_damageable)
	enemy.enemy_died.connect(_on_enemy_died)

	_active_enemies.append(enemy)

	return enemy


func _clear_active_enemies() -> void:
	for enemy: Enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

	_active_enemies.clear()


func _on_enemy_died(
	enemy: CharacterBody3D,
	_damage_info: DamageInfo
) -> void:
	var typed_enemy: Enemy = enemy as Enemy

	if typed_enemy == null:
		return

	_active_enemies.erase(typed_enemy)


func _get_valid_player() -> CharacterBody3D:
	if is_instance_valid(_player):
		return _player

	DeveloperConsole.log_error("Player is unavailable.")
	return null


func _parse_positive_amount(value: String, label: String) -> float:
	if not value.is_valid_float():
		DeveloperConsole.log_error("%s must be a number." % label)
		return 0.0

	var amount: float = value.to_float()

	if amount <= 0.0:
		DeveloperConsole.log_error("%s must be greater than zero." % label)
		return 0.0

	return amount
