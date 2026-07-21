class_name CrosshairPresentationDefinition
extends Resource

enum SplitMode {
	NONE,
	PLUS_FOUR_ARMS,
	VERTICAL_HALVES,
	HORIZONTAL_HALVES,
	THREE_VERTICAL,
	FOUR_CORNERS,
}

@export_category("Crosshair")
@export var is_crosshair_enabled: bool = true
@export var crosshair_texture: Texture2D

@export var split_mode: SplitMode = SplitMode.NONE

@export_range(1, 4096, 1, "suffix:px")
var plus_arm_thickness_px: int = 4

@export_range(0, 4096, 1, "suffix:px")
var plus_center_gap_px: int = 8

@export_range(0.1, 10.0, 0.01)
var crosshair_scale: float = 1.0

@export var crosshair_modulate: Color = Color.WHITE


@export_category("Dot")
@export var is_dot_enabled: bool = true
@export var dot_texture: Texture2D

@export_range(0.1, 10.0, 0.01)
var dot_scale: float = 1.0

@export var dot_modulate: Color = Color.WHITE


@export_category("Hitmarker")
@export var is_hitmarker_enabled: bool = true
@export var hitmarker_texture: Texture2D

@export_range(0.1, 10.0, 0.01)
var hitmarker_scale: float = 1.0

@export var hitmarker_modulate: Color = Color.WHITE
@export var critical_hitmarker_modulate: Color = Color(
	1.0,
	0.25,
	0.1,
	1.0
)

@export_range(0.0, 1.0, 0.001, "suffix:s")
var hitmarker_duration_s: float = 0.09

@export_range(0.1, 100.0, 0.1, "suffix:1/s")
var hitmarker_fade_speed: float = 24.0


@export_category("Fire Separation")
@export_range(0.0, 500.0, 0.1, "suffix:px")
var fire_separation_px: float = 8.0

@export_range(0.1, 100.0, 0.1, "suffix:1/s")
var separation_return_speed: float = 22.0


@export_category("Weapon Switch")
@export var is_switch_enter_separation_enabled: bool = true

@export_range(0.0, 500.0, 0.1, "suffix:px")
var switch_enter_separation_px: float = 18.0


@export_category("Reload Rotation")
@export var is_reload_rotation_enabled: bool = false


func get_validation_error() -> String:
	if crosshair_scale <= 0.0:
		return "crosshair_scale must be greater than zero."

	if dot_scale <= 0.0:
		return "dot_scale must be greater than zero."

	if hitmarker_scale <= 0.0:
		return "hitmarker_scale must be greater than zero."

	if separation_return_speed <= 0.0:
		return (
			"separation_return_speed must be greater than zero."
		)

	if hitmarker_fade_speed <= 0.0:
		return (
			"hitmarker_fade_speed must be greater than zero."
		)

	if plus_arm_thickness_px <= 0:
		return (
			"plus_arm_thickness_px must be greater than zero."
		)

	if plus_center_gap_px < 0:
		return "plus_center_gap_px must not be negative."

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()
