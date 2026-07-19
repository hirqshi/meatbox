class_name CameraJuiceComponent
extends Node3D

@export var definition: CameraJuiceDefinition
@export var camera: Camera3D

var _body: CharacterBody3D
var _movement_definition: PlayerDefinition
var _base_fov_deg: float = 75.0
var _is_enabled: bool = true

var _idle_phase: float = 0.0
var _move_phase: float = 0.0

var _current_fov_deg: float = 75.0
var _current_strafe_roll_rad: float = 0.0
var _current_look_roll_rad: float = 0.0
var _current_look_pitch_rad: float = 0.0

var _look_roll_target_rad: float = 0.0
var _look_pitch_target_rad: float = 0.0

var _landing_offset_y: float = 0.0
var _landing_target_offset_y: float = 0.0
var _landing_velocity_y: float = 0.0
var _landing_bob_suppression: float = 0.0


var _movement_bob_weight: float = 0.0


func setup(body: CharacterBody3D, movement_definition: PlayerDefinition) -> void:
	assert(body != null, "CameraJuiceComponent requires a CharacterBody3D.")
	assert(movement_definition != null, "CameraJuiceComponent requires a PlayerDefinition.")
	assert(definition != null, "CameraJuiceComponent requires a CameraJuiceDefinition.")
	assert(camera != null, "CameraJuiceComponent requires a Camera3D.")
	assert(
		definition.is_valid(),
		"Invalid camera juice definition '%s': %s"
		% [
			definition.resource_path,
			definition.get_validation_error(),
		]
	)

	_body = body
	_movement_definition = movement_definition
	_base_fov_deg = camera.fov
	_current_fov_deg = _base_fov_deg


func set_is_enabled(value: bool) -> void:
	if _is_enabled == value:
		return

	_is_enabled = value

	if _is_enabled:
		return

	_reset_transform()


func register_look_delta(mouse_delta: Vector2) -> void:
	if not _is_enabled:
		return

	_look_roll_target_rad = clampf(
		-mouse_delta.x * definition.mouse_delta_to_inertia,
		-deg_to_rad(definition.yaw_inertia_roll_deg),
		deg_to_rad(definition.yaw_inertia_roll_deg)
	)
	_look_pitch_target_rad = clampf(
		mouse_delta.y * definition.mouse_delta_to_inertia,
		-deg_to_rad(definition.pitch_inertia_pitch_deg),
		deg_to_rad(definition.pitch_inertia_pitch_deg)
	)


func register_landing( fall_speed_mps: float, horizontal_speed_mps: float ) -> void:
	if not _is_enabled:
		return

	var landing_speed_ratio: float = clampf(
		fall_speed_mps / definition.max_landing_speed_mps,
		0.0,
		1.0
	)
	var horizontal_speed_ratio: float = clampf(
		horizontal_speed_mps / _movement_definition.run_speed_mps,
		0.0,
		1.0
	)
	
	var run_offset_multiplier: float = lerpf(
		1.0,
		definition.landing_run_offset_multiplier,
		horizontal_speed_ratio
	)
	
	var landing_drop_m: float = (
		definition.landing_offset_m
		* landing_speed_ratio
		* run_offset_multiplier
	)

	if landing_drop_m <= 0.0:
		return

	_landing_target_offset_y = minf(
		_landing_target_offset_y - landing_drop_m,
		-definition.landing_offset_m
	)
	var bob_suppression: float = (
		definition.landing_bob_suppression
		+ definition.landing_run_bob_suppression_bonus * horizontal_speed_ratio
	)

	_landing_bob_suppression = maxf(
		_landing_bob_suppression,
		clampf(bob_suppression * landing_speed_ratio, 0.0, 0.95)
	)


func physics_update(delta: float) -> void:
	if _body == null or _movement_definition == null or camera == null:
		return

	if not _is_enabled:
		return

	var horizontal_speed_mps: float = Vector2(
		_body.velocity.x,
		_body.velocity.z
	).length()

	var speed_ratio: float = clampf(
		horizontal_speed_mps / _movement_definition.run_speed_mps,
		0.0,
		1.0
	)

	_update_landing_spring(delta)
	_update_fov(delta, speed_ratio)
	_update_bob(delta, speed_ratio)
	_update_movement_bob_weight(delta, speed_ratio)
	_update_rotation(delta)
	_apply_transform()


func _update_landing_spring(delta: float) -> void:
	var target_response_weight: float = _get_smoothing_weight(
		definition.landing_impact_response_speed,
		delta
	)

	_landing_target_offset_y = lerpf(
		_landing_target_offset_y,
		0.0,
		target_response_weight
	)

	var acceleration_y: float = (
		(_landing_target_offset_y - _landing_offset_y)
		* definition.landing_spring_strength
		- _landing_velocity_y * definition.landing_spring_damping
	)

	_landing_velocity_y += acceleration_y * delta
	_landing_offset_y += _landing_velocity_y * delta
	
	_landing_bob_suppression = lerpf(
		_landing_bob_suppression,
		0.0,
		_get_smoothing_weight(definition.landing_bob_restore_speed, delta)
	)


func _update_fov(delta: float, speed_ratio: float) -> void:
	var airborne_fov_bonus_deg: float = 0.0

	if not _body.is_on_floor():
		airborne_fov_bonus_deg = definition.airborne_fov_bonus_deg

	var target_fov_deg: float = (
		_base_fov_deg
		+ definition.max_speed_fov_bonus_deg * speed_ratio
		+ airborne_fov_bonus_deg
	)

	_current_fov_deg = lerpf(
		_current_fov_deg,
		target_fov_deg,
		_get_smoothing_weight(definition.fov_response_speed, delta)
	)
	camera.fov = _current_fov_deg


func _update_bob(delta: float, speed_ratio: float) -> void:
	_idle_phase += TAU * definition.idle_bob_frequency_hz * delta

	if speed_ratio >= definition.minimum_bob_speed_ratio and _body.is_on_floor():
		var move_frequency_hz: float = (
			definition.move_bob_base_frequency_hz
			+ definition.move_bob_speed_frequency_hz * speed_ratio
		)
		_move_phase += TAU * move_frequency_hz * delta


func _update_movement_bob_weight(
	delta: float,
	speed_ratio: float
) -> void:
	var target_weight: float = 0.0

	if _body.is_on_floor():
		target_weight = smoothstep(
			definition.minimum_bob_speed_ratio,
			1.0,
			speed_ratio
		)

	_movement_bob_weight = lerpf(
		_movement_bob_weight,
		target_weight,
		_get_smoothing_weight(14.0, delta)
	)
	
	
func _update_rotation(delta: float) -> void:
	var strafe_input: float = Input.get_axis(&"move_left", &"move_right")
	var strafe_roll_target_rad: float = deg_to_rad(
		-definition.strafe_lean_deg * strafe_input
	)

	_current_strafe_roll_rad = lerpf(
		_current_strafe_roll_rad,
		strafe_roll_target_rad,
		_get_smoothing_weight(definition.strafe_lean_response_speed, delta)
	)
	_current_look_roll_rad = lerpf(
		_current_look_roll_rad,
		_look_roll_target_rad,
		_get_smoothing_weight(definition.look_inertia_response_speed, delta)
	)
	_current_look_pitch_rad = lerpf(
		_current_look_pitch_rad,
		_look_pitch_target_rad,
		_get_smoothing_weight(definition.look_inertia_response_speed, delta)
	)

	_look_roll_target_rad = lerpf(
		_look_roll_target_rad,
		0.0,
		_get_smoothing_weight(definition.look_inertia_response_speed, delta)
	)
	_look_pitch_target_rad = lerpf(
		_look_pitch_target_rad,
		0.0,
		_get_smoothing_weight(definition.look_inertia_response_speed, delta)
	)


func _apply_transform() -> void:
	var idle_offset: Vector3 = Vector3(
		cos(_idle_phase) * definition.idle_bob_horizontal_m,
		sin(_idle_phase) * definition.idle_bob_vertical_m,
		0.0
	)

	var movement_bob_multiplier: float = (
		1.0 - _landing_bob_suppression
	)

	var movement_offset: Vector3 = Vector3(
		cos(_move_phase)
		* definition.move_bob_horizontal_m
		* _movement_bob_weight
		* movement_bob_multiplier,
		absf(sin(_move_phase))
		* definition.move_bob_vertical_m
		* _movement_bob_weight
		* movement_bob_multiplier,
		0.0
	)

	position = idle_offset + movement_offset + Vector3.UP * _landing_offset_y
	rotation = Vector3(
		_current_look_pitch_rad,
		0.0,
		_current_strafe_roll_rad + _current_look_roll_rad
	)
	
	
func _reset_transform() -> void:
	_idle_phase = 0.0
	_move_phase = 0.0

	_current_fov_deg = _base_fov_deg
	_current_strafe_roll_rad = 0.0
	_current_look_roll_rad = 0.0
	_current_look_pitch_rad = 0.0

	_look_roll_target_rad = 0.0
	_look_pitch_target_rad = 0.0

	_landing_offset_y = 0.0
	_landing_target_offset_y = 0.0
	_landing_velocity_y = 0.0
	_landing_bob_suppression = 0.0
	_movement_bob_weight = 0.0

	camera.fov = _base_fov_deg
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	
	
func _get_smoothing_weight(response_speed: float, delta: float) -> float:
	return 1.0 - exp(-response_speed * delta)
