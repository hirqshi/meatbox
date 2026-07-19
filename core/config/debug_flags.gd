class_name DebugFlags
extends Resource

@export_category("General")
@export var is_console_enabled: bool = true
@export var is_overlay_enabled_on_start: bool = true

@export_category("Generation")
@export var show_generation_bounds: bool = false
@export var show_generation_connectors: bool = false
@export var show_spawn_markers: bool = false

@export_category("Combat")
@export var show_hitboxes: bool = false
@export var show_hurtboxes: bool = false
@export var show_projectile_paths: bool = false
