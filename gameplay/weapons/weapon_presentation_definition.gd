class_name WeaponPresentationDefinition
extends Resource

@export_category("Sprite Frames")
@export var sprite_frames: SpriteFrames

@export_category("Animations")
@export var default_animation_name: StringName = &"default"
@export var fire_animation_name: StringName = &"fire"
@export var reload_animation_name: StringName = &"reload"

@export_category("View Transform")
@export var view_offset: Vector3 = Vector3(
	0.6,
	-0.45,
	-0.85
)

@export var view_rotation_degrees: Vector3 = Vector3.ZERO

@export_range(0.01, 10.0, 0.01)
var view_scale: float = 1.0

@export_category("Idle Motion")
@export_range(0.0, 10.0, 0.01, "suffix:Hz")
var idle_bob_frequency_hz: float = 0.4

@export_range(0.0, 0.2, 0.001, "suffix:m")
var idle_bob_horizontal_m: float = 0.008

@export_range(0.0, 0.2, 0.001, "suffix:m")
var idle_bob_vertical_m: float = 0.01

@export_category("Movement Motion")
@export_range(0.0, 0.1, 0.001)
var minimum_bob_speed_ratio: float = 0.08

@export_range(0.0, 20.0, 0.01, "suffix:Hz")
var move_bob_base_frequency_hz: float = 1.1

@export_range(0.0, 20.0, 0.01, "suffix:Hz")
var move_bob_speed_frequency_hz: float = 1.1

@export_range(0.0, 0.2, 0.001, "suffix:m")
var move_bob_horizontal_m: float = 0.03

@export_range(0.0, 0.2, 0.001, "suffix:m")
var move_bob_vertical_m: float = 0.03

@export_range(0.0, 40.0, 0.01, "suffix:deg")
var strafe_tilt_deg: float = 3.5

@export_range(0.0, 40.0, 0.01, "suffix:deg")
var vertical_velocity_tilt_deg: float = 15.0

@export_range(0.01, 100.0, 0.01, "suffix:m/s")
var vertical_tilt_max_speed_mps: float = 27.5

@export_range(0.0, 60.0, 0.01, "suffix:1/s")
var motion_response_speed: float = 12.0

@export_category("Look Inertia")
@export_range(0.0, 1.0, 0.0001)
var mouse_delta_to_inertia: float = 0.03

@export_range(0.0, 30.0, 0.01, "suffix:deg")
var yaw_inertia_roll_deg: float = 4.5

@export_range(0.0, 30.0, 0.01, "suffix:deg")
var pitch_inertia_pitch_deg: float = 4.5

@export_range(0.0, 60.0, 0.01, "suffix:1/s")
var look_inertia_response_speed: float = 14.0

@export_category("Landing Motion")
@export_range(0.0, 0.5, 0.001, "suffix:m")
var landing_offset_m: float = 0.15

@export_range(0.01, 100.0, 0.01, "suffix:m/s")
var max_landing_speed_mps: float = 15.0

@export_range(0.0, 1000.0, 0.01)
var landing_spring_strength: float = 180.0

@export_range(0.0, 100.0, 0.01)
var landing_spring_damping: float = 20.0

@export_range(0.0, 60.0, 0.01, "suffix:1/s")
var landing_impact_response_speed: float = 7.0

@export_category("Fire Juice")
@export var fire_kick_position_m: Vector3 = Vector3(
	0.0,
	-0.04,
	0.27
)

@export var fire_kick_rotation_degrees: Vector3 = Vector3(
	-4.0,
	0.8,
	2.4
)

@export var fire_shake_position_m: Vector3 = Vector3(
	0.006,
	0.006,
	0.003
)

@export var fire_shake_rotation_degrees: Vector3 = Vector3(
	0.45,
	0.45,
	0.8
)

@export_range(0.0, 1.0, 0.01, "suffix:s")
var fire_shake_duration_s: float = 0.06

@export_range(0.0, 100.0, 0.01, "suffix:1/s")
var recoil_return_speed: float = 11.81

@export_category("Equip Transition")
@export var hidden_offset: Vector3 = Vector3(
	0.18,
	-0.8,
	0.18
)

@export_range(0.01, 3.0, 0.01, "suffix:s")
var equip_duration_s: float = 0.34

@export_range(0.01, 3.0, 0.01, "suffix:s")
var unequip_duration_s: float = 0.2


func get_validation_error(
	requires_reload_animation: bool
) -> String:
	if sprite_frames == null:
		return "sprite_frames must not be null."

	if not sprite_frames.has_animation(
		default_animation_name
	):
		return (
			"Missing default animation '%s'."
			% default_animation_name
		)

	if not sprite_frames.has_animation(
		fire_animation_name
	):
		return (
			"Missing fire animation '%s'."
			% fire_animation_name
		)

	if requires_reload_animation:
		if not sprite_frames.has_animation(
			reload_animation_name
		):
			return (
				"Missing reload animation '%s'."
				% reload_animation_name
			)

	if view_scale <= 0.0:
		return "view_scale must be greater than zero."

	if vertical_tilt_max_speed_mps <= 0.0:
		return (
			"vertical_tilt_max_speed_mps must be greater than zero."
		)

	return ""


func is_valid(
	requires_reload_animation: bool
) -> bool:
	return get_validation_error(
		requires_reload_animation
	).is_empty()
