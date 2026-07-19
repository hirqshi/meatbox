extends Node

const PLAYER_SCENE: PackedScene = preload("res://gameplay/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://gameplay/enemies/enemy.tscn")

@export var enemy_spawn_position: Vector3 = Vector3(0.0, 1.0, -10.0)
@export var default_run_config: RunConfig
@export var player_spawn_position: Vector3 = Vector3(0.0, 3.0, 0.0)

@onready var _gameplay_root: Node = $GameplayRoot

func _ready() -> void:
	assert(default_run_config != null, "GameRoot requires a default RunConfig.")

	DeveloperConsole.log_info(
		"GameRoot ready. Seed: %d" % default_run_config.run_seed
	)

	if not RunSession.is_run_active():
		RunSession.start_run(default_run_config)

	var player: CharacterBody3D = _spawn_player()
	_spawn_test_enemy(player)


func _spawn_player() -> CharacterBody3D:
	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D

	assert(player != null, "Player scene root must inherit CharacterBody3D.")

	_gameplay_root.add_child(player)
	player.global_position = player_spawn_position

	return player


func _spawn_test_enemy(player: CharacterBody3D) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy

	assert(enemy != null, "Enemy scene root must inherit CharacterBody3D.")

	_gameplay_root.add_child(enemy)
	enemy.global_position = enemy_spawn_position

	var target_damageable: Damageable = (
		player.get_node_or_null("HealthComponent") as Damageable
	)
	assert(target_damageable != null, "Player requires a HealthComponent.")

	var enemy_controller: Node = enemy
	enemy.setup_target(player, target_damageable)
	
