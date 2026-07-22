class_name OrganPresentationSettings
extends Resource

@export_category("Global Scale")
@export_range(0.1, 8.0, 0.01)
var global_icon_scale: float = 1.0:
	set(value):
		global_icon_scale = maxf(value, 0.1)
		emit_changed()

@export_range(0.1, 8.0, 0.01)
var global_collision_scale: float = 1.0:
	set(value):
		global_collision_scale = maxf(value, 0.1)
		emit_changed()

@export_category("Drag")
@export_range(0.1, 4.0, 0.01)
var drag_proxy_scale_multiplier: float = 1.0:
	set(value):
		drag_proxy_scale_multiplier = maxf(value, 0.1)
		emit_changed()

@export_category("Draw Order")
@export_range(-4096, 4096, 1)
var installed_visual_z_index: int = 10:
	set(value):
		installed_visual_z_index = value
		emit_changed()

@export_range(-4096, 4096, 1)
var drag_visual_z_index: int = 100:
	set(value):
		drag_visual_z_index = value
		emit_changed()
