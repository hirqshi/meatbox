extends Node

const GAME_ROOT_SCENE: PackedScene = preload("res://scenes/game/game_root.tscn")

var _active_game_root: Node


func start_game(config: RunConfig) -> void:
	assert(config != null, "SceneFlow requires a valid RunConfig.")

	TimeController.reset()
	RunSession.end_run()

	var current_scene: Node = get_tree().current_scene

	if current_scene != null:
		current_scene.queue_free()

	_active_game_root = GAME_ROOT_SCENE.instantiate()
	get_tree().root.add_child(_active_game_root)
	get_tree().current_scene = _active_game_root

	RunSession.start_run(config)


func return_to_menu() -> void:
	TimeController.reset()
	RunSession.end_run()

	if _active_game_root != null and is_instance_valid(_active_game_root):
		_active_game_root.queue_free()

	_active_game_root = null
