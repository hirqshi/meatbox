class_name RunRandom
extends RefCounted

var _run_seed: int


func _init(run_seed: int) -> void:
	_run_seed = run_seed


func create_stream(stream_name: StringName, salt: int = 0) -> RandomNumberGenerator:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = _derive_seed(stream_name, salt)
	return random


func get_run_seed() -> int:
	return _run_seed


func _derive_seed(stream_name: StringName, salt: int) -> int:
	var stream_hash: int = hash(stream_name)
	var mixed_seed: int = _run_seed ^ stream_hash ^ salt

	return abs(mixed_seed)
