class_name OrganVisualDefinition
extends Resource

@export_category("Icon")
@export var icon: Texture2D
@export var tint: Color = Color.WHITE

@export_category("Sizing")
@export_range(0.1, 8.0, 0.01)
var visual_scale: float = 1.0

@export_range(0.1, 8.0, 0.01)
var collision_scale: float = 1.0

@export_category("Motion")
@export_range(0.01, 1.0, 0.01, "suffix:s")
var move_duration_sec: float = 0.12

@export_range(0.01, 1.0, 0.01, "suffix:s")
var hover_duration_sec: float = 0.08

@export_range(1.0, 1.5, 0.01)
var hover_scale_multiplier: float = 1.06

@export_category("Click Shake")
@export_range(0.0, 64.0, 0.5, "suffix:px")
var click_shake_offset_px: float = 4.0

@export_range(0.0, 64.0, 0.5, "suffix:px")
var click_shake_secondary_offset_px: float = 1.5

@export_range(0.0, 360.0, 1.0, "suffix:deg")
var click_shake_axis_deg: float = 0.0

@export_range(0.0, 360.0, 1.0, "suffix:deg")
var click_shake_secondary_axis_deg: float = 90.0

@export_range(0.0, 40.0, 0.5, "suffix:hz")
var click_shake_frequency_hz: float = 18.0

@export_range(0.0, 40.0, 0.5, "suffix:hz")
var click_shake_secondary_frequency_hz: float = 31.0

@export_range(0.0, 45.0, 0.1, "suffix:deg")
var click_shake_rotation_deg: float = 3.0

@export_range(0.01, 1.0, 0.01, "suffix:s")
var click_shake_duration_sec: float = 0.10

@export_category("Insert Shake")
@export_range(0.0, 64.0, 0.5, "suffix:px")
var insert_shake_offset_px: float = 6.0

@export_range(0.0, 64.0, 0.5, "suffix:px")
var insert_shake_secondary_offset_px: float = 2.5

@export_range(0.0, 360.0, 1.0, "suffix:deg")
var insert_shake_axis_deg: float = 0.0

@export_range(0.0, 360.0, 1.0, "suffix:deg")
var insert_shake_secondary_axis_deg: float = 90.0

@export_range(0.0, 40.0, 0.5, "suffix:hz")
var insert_shake_frequency_hz: float = 14.0

@export_range(0.0, 40.0, 0.5, "suffix:hz")
var insert_shake_secondary_frequency_hz: float = 25.0

@export_range(0.0, 45.0, 0.1, "suffix:deg")
var insert_shake_rotation_deg: float = 5.0

@export_range(0.01, 1.0, 0.01, "suffix:s")
var insert_shake_duration_sec: float = 0.14
