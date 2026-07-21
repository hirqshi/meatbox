class_name CameraJuiceDefinition
extends Resource

@export_category("Fov")
@export_range(0.0, 60.0, 0.1, "suffix:deg") var max_speed_fov_bonus_deg: float = 8.0
@export_range(0.0, 60.0, 0.1, "suffix:deg") var airborne_fov_bonus_deg: float = 3.0
@export_range(0.1, 50.0, 0.1) var fov_response_speed: float = 11.0

@export_category("Idle Bob")
@export_range(0.0, 1.0, 0.001, "suffix:m") var idle_bob_horizontal_m: float = 0.008
@export_range(0.0, 1.0, 0.001, "suffix:m") var idle_bob_vertical_m: float = 0.012
@export_range(0.0, 10.0, 0.01, "suffix:hz") var idle_bob_frequency_hz: float = 0.8

@export_category("Movement Bob")
@export_range(0.0, 1.0, 0.001, "suffix:m") var move_bob_horizontal_m: float = 0.035
@export_range(0.0, 1.0, 0.001, "suffix:m") var move_bob_vertical_m: float = 0.045
@export_range(0.0, 20.0, 0.01, "suffix:hz") var move_bob_base_frequency_hz: float = 1.5
@export_range(0.0, 20.0, 0.01, "suffix:hz") var move_bob_speed_frequency_hz: float = 7.0
@export_range(0.0, 1.0, 0.01) var minimum_bob_speed_ratio: float = 0.08

@export_category("Strafe Lean")
@export_range(0.0, 30.0, 0.1, "suffix:deg") var strafe_lean_deg: float = 4.0
@export_range(0.1, 50.0, 0.1) var strafe_lean_response_speed: float = 12.0

@export_category("Look Inertia")
@export_range(0.0, 30.0, 0.01, "suffix:deg") var yaw_inertia_roll_deg: float = 5.0
@export_range(0.0, 30.0, 0.01, "suffix:deg") var pitch_inertia_pitch_deg: float = 2.0
@export_range(0.0, 1.0, 0.0001) var mouse_delta_to_inertia: float = 0.018
@export_range(0.1, 50.0, 0.1) var look_inertia_response_speed: float = 16.0

@export_category("Landing Spring")
@export_range(0.0, 2.0, 0.001, "suffix:m") var landing_offset_m: float = 0.085
@export_range(0.0, 100.0, 0.1) var landing_spring_strength: float = 55.0
@export_range(0.0, 100.0, 0.1) var landing_spring_damping: float = 13.0
@export_range(0.0, 100.0, 0.1, "suffix:m/s") var max_landing_speed_mps: float = 22.0
@export_range(0.1, 50.0, 0.1) var landing_impact_response_speed: float = 22.0
@export_range(0.0, 1.0, 0.01) var landing_bob_suppression: float = 0.65
@export_range(0.1, 50.0, 0.1) var landing_bob_restore_speed: float = 9.0
@export_range(1.0, 4.0, 0.05) var landing_run_offset_multiplier: float = 1.8
@export_range(0.0, 1.0, 0.01) var landing_run_bob_suppression_bonus: float = 0.2

@export_category("Damage Feedback")
@export_range(0.0, 1.0, 0.001)
var damage_feedback_full_strength_health_ratio: float = 0.3

@export_range(0.0, 1.0, 0.001, "suffix:m")
var damage_kick_min_position_m: float = 0.008

@export_range(0.0, 1.0, 0.001, "suffix:m")
var damage_kick_max_position_m: float = 0.035

@export_range(0.0, 20.0, 0.1, "suffix:deg")
var damage_kick_min_rotation_deg: float = 0.45

@export_range(0.0, 20.0, 0.1, "suffix:deg")
var damage_kick_max_rotation_deg: float = 3.0

@export_range(0.0, 1.0, 0.001, "suffix:s")
var damage_kick_hold_duration_s: float = 0.02

@export_range(0.1, 100.0, 0.1, "suffix:1/s")
var damage_kick_return_speed: float = 16.0

@export_range(0.0, 1.0, 0.001, "suffix:m")
var damage_shake_min_position_m: float = 0.002

@export_range(0.0, 1.0, 0.001, "suffix:m")
var damage_shake_max_position_m: float = 0.012

@export_range(0.0, 20.0, 0.1, "suffix:deg")
var damage_shake_min_rotation_deg: float = 0.18

@export_range(0.0, 20.0, 0.1, "suffix:deg")
var damage_shake_max_rotation_deg: float = 1.2

@export_range(0.0, 1.0, 0.001, "suffix:s")
var damage_shake_duration_s: float = 0.13

@export_range(1.0, 120.0, 0.1, "suffix:Hz")
var damage_shake_frequency_hz: float = 30.0


func get_validation_error() -> String:
	if fov_response_speed <= 0.0:
		return "fov_response_speed must be greater than zero."

	if idle_bob_frequency_hz < 0.0:
		return "idle_bob_frequency_hz must not be negative."

	if move_bob_base_frequency_hz < 0.0:
		return "move_bob_base_frequency_hz must not be negative."

	if move_bob_speed_frequency_hz < 0.0:
		return "move_bob_speed_frequency_hz must not be negative."

	if strafe_lean_response_speed <= 0.0:
		return "strafe_lean_response_speed must be greater than zero."

	if look_inertia_response_speed <= 0.0:
		return "look_inertia_response_speed must be greater than zero."

	if landing_spring_strength <= 0.0:
		return "landing_spring_strength must be greater than zero."

	if landing_spring_damping < 0.0:
		return "landing_spring_damping must not be negative."

	if max_landing_speed_mps <= 0.0:
		return "max_landing_speed_mps must be greater than zero."

	if landing_bob_restore_speed <= 0.0:
		return "landing_bob_restore_speed must be greater than zero."
	
	if landing_run_offset_multiplier < 1.0:
		return "landing_run_offset_multiplier must be at least one."

	if landing_run_bob_suppression_bonus < 0.0:
		return "landing_run_bob_suppression_bonus must not be negative."
	
	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()
