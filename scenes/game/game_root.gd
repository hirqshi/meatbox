extends Node

const PLAYER_SCENE: PackedScene = preload("res://gameplay/player/player.tscn")

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

	_spawn_player()


func _spawn_player() -> void:
	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D

	assert(player != null, "Player scene root must inherit CharacterBody3D.")

	_gameplay_root.add_child(player)
	player.global_position = player_spawn_position
