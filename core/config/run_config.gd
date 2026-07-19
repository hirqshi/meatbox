class_name RunConfig
extends Resource

@export_category("Identity")
@export var run_name: StringName = &"dev_sandbox"
@export var run_seed: int = 1

@export_category("Flow")
@export_range(1, 99, 1) var starting_floor_index: int = 1

@export_category("Debug")
@export var debug_flags: DebugFlags
