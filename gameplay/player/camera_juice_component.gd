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

var _kick_position: Vector3 = Vector3.ZERO
var _kick_rotation_rad: Vector3 = Vector3.ZERO
var _kick_hold_remaining_s: float = 0.0
var _kick_return_speed: float = 0.0

var _shake_remaining_s: float = 0.0
var _shake_duration_s: float = 0.0
var _shake_frequency_hz: float = 0.0
var _shake_sample_elapsed_s: float = 0.0
var _shake_position_amplitude_m: Vector3 = Vector3.ZERO
var _shake_rotation_amplitude_rad: Vector3 = Vector3.ZERO
var _shake_position_target: Vector3 = Vector3.ZERO
var _shake_rotation_target_rad: Vector3 = Vector3.ZERO
var _shake_position: Vector3 = Vector3.ZERO
var _shake_rotation_rad: Vector3 = Vector3.ZERO

var _random: RandomNumberGenerator = RandomNumberGenerator.new()



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


func play_weapon_fire_feedback(
	weapon: WeaponInstance
) -> void:
	if weapon == null:
		return

	var presentation: WeaponPresentationDefinition = (
		weapon.definition.view_presentation
	)

	if presentation == null:
		return

	play_kick(
		presentation.fire_camera_kick_position_m,
		presentation.fire_camera_kick_rotation_degrees,
		presentation.fire_camera_kick_hold_duration_s,
		presentation.fire_camera_kick_return_speed,
		presentation.fire_camera_max_kick_position_m,
		presentation.fire_camera_max_kick_rotation_deg
	)

	play_shake(
		presentation.fire_camera_shake_position_m,
		presentation.fire_camera_shake_rotation_degrees,
		presentation.fire_camera_shake_duration_s,
		presentation.fire_camera_shake_frequency_hz
	)


func play_damage_feedback(
	damage_info: DamageInfo,
	applied_damage: float
) -> void:
	if not _is_enabled:
		return

	if damage_info == null or applied_damage <= 0.0:
		return

	var max_health: float = _get_owner_max_health()

	if max_health <= 0.0:
		return

	var damage_ratio: float = clampf(
		applied_damage / max_health,
		0.0,
		1.0
	)

	var damage_strength: float = clampf(
		damage_ratio
		/ maxf(
			definition.damage_feedback_full_strength_health_ratio,
			0.001
		),
		0.0,
		1.0
	)

	var kick_position_strength_m: float = lerpf(
		definition.damage_kick_min_position_m,
		definition.damage_kick_max_position_m,
		damage_strength
	)

	var kick_rotation_strength_deg: float = lerpf(
		definition.damage_kick_min_rotation_deg,
		definition.damage_kick_max_rotation_deg,
		damage_strength
	)

	var shake_position_strength_m: float = lerpf(
		definition.damage_shake_min_position_m,
		definition.damage_shake_max_position_m,
		damage_strength
	)

	var shake_rotation_strength_deg: float = lerpf(
		definition.damage_shake_min_rotation_deg,
		definition.damage_shake_max_rotation_deg,
		damage_strength
	)

	var local_push_direction: Vector3 = (
		_get_local_damage_push_direction(
			damage_info.hit_direction
		)
	)

	var kick_position: Vector3 = Vector3(
		local_push_direction.x * kick_position_strength_m,
		0.0,
		local_push_direction.z * kick_position_strength_m
	)

	var kick_rotation_degrees: Vector3 = Vector3(
		local_push_direction.z * kick_rotation_strength_deg,
		-local_push_direction.x * kick_rotation_strength_deg,
		0.0
	)

	play_kick(
		kick_position,
		kick_rotation_degrees,
		definition.damage_kick_hold_duration_s,
		definition.damage_kick_return_speed,
		definition.damage_kick_max_position_m,
		definition.damage_kick_max_rotation_deg
	)

	play_shake(
		Vector3.ONE * shake_position_strength_m,
		Vector3.ONE * shake_rotation_strength_deg,
		definition.damage_shake_duration_s,
		definition.damage_shake_frequency_hz
	)


func play_kick(
	position_offset_m: Vector3,
	rotation_offset_degrees: Vector3,
	hold_duration_s: float,
	return_speed: float,
	max_position_m: float,
	max_rotation_deg: float
) -> void:
	if not _is_enabled:
		return

	_kick_position += position_offset_m

	if max_position_m > 0.0:
		_kick_position = _kick_position.limit_length(
			max_position_m
		)

	_kick_rotation_rad += _to_radians(
		rotation_offset_degrees
	)

	if max_rotation_deg > 0.0:
		_kick_rotation_rad = _kick_rotation_rad.limit_length(
			deg_to_rad(max_rotation_deg)
		)

	_kick_hold_remaining_s = maxf(
		_kick_hold_remaining_s,
		maxf(hold_duration_s, 0.0)
	)
	_kick_return_speed = maxf(return_speed, 0.1)


func play_shake(
	position_amplitude_m: Vector3,
	rotation_amplitude_degrees: Vector3,
	duration_s: float,
	frequency_hz: float
) -> void:
	if not _is_enabled:
		return

	if duration_s <= 0.0:
		return

	_shake_position_amplitude_m = _max_vector_components(
		_shake_position_amplitude_m,
		position_amplitude_m
	)
	_shake_rotation_amplitude_rad = _max_vector_components(
		_shake_rotation_amplitude_rad,
		_to_radians(rotation_amplitude_degrees)
	)

	_shake_duration_s = maxf(_shake_duration_s, duration_s)
	_shake_remaining_s = maxf(_shake_remaining_s, duration_s)
	_shake_frequency_hz = maxf(_shake_frequency_hz, frequency_hz)
	


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
	_update_feedback(delta)
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


func _update_feedback(delta: float) -> void:
	if _kick_hold_remaining_s > 0.0:
		_kick_hold_remaining_s = maxf(
			_kick_hold_remaining_s - delta,
			0.0
		)
	else:
		var kick_return_weight: float = _get_smoothing_weight(
			_kick_return_speed,
			delta
		)

		_kick_position = _kick_position.lerp(
			Vector3.ZERO,
			kick_return_weight
		)
		_kick_rotation_rad = _kick_rotation_rad.lerp(
			Vector3.ZERO,
			kick_return_weight
		)

	if _shake_remaining_s <= 0.0:
		_shake_position = Vector3.ZERO
		_shake_rotation_rad = Vector3.ZERO
		_shake_position_target = Vector3.ZERO
		_shake_rotation_target_rad = Vector3.ZERO
		_shake_position_amplitude_m = Vector3.ZERO
		_shake_rotation_amplitude_rad = Vector3.ZERO
		_shake_duration_s = 0.0
		_shake_sample_elapsed_s = 0.0
		return

	_shake_remaining_s = maxf(_shake_remaining_s - delta, 0.0)
	_shake_sample_elapsed_s += delta

	var sample_interval_s: float = 1.0 / maxf(
		_shake_frequency_hz,
		1.0
	)

	if _shake_sample_elapsed_s >= sample_interval_s:
		_shake_sample_elapsed_s = 0.0

		_shake_position_target = Vector3(
			_random.randf_range(-1.0, 1.0)
			* _shake_position_amplitude_m.x,
			_random.randf_range(-1.0, 1.0)
			* _shake_position_amplitude_m.y,
			_random.randf_range(-1.0, 1.0)
			* _shake_position_amplitude_m.z
		)

		_shake_rotation_target_rad = Vector3(
			_random.randf_range(-1.0, 1.0)
			* _shake_rotation_amplitude_rad.x,
			_random.randf_range(-1.0, 1.0)
			* _shake_rotation_amplitude_rad.y,
			_random.randf_range(-1.0, 1.0)
			* _shake_rotation_amplitude_rad.z
		)

	var sample_response_speed: float = (
		maxf(_shake_frequency_hz, 1.0) * 2.5
	)
	var sample_weight: float = _get_smoothing_weight(
		sample_response_speed,
		delta
	)
	var fade_weight: float = _shake_remaining_s / maxf(
		_shake_duration_s,
		0.001
	)

	_shake_position = _shake_position.lerp(
		_shake_position_target * fade_weight,
		sample_weight
	)
	_shake_rotation_rad = _shake_rotation_rad.lerp(
		_shake_rotation_target_rad * fade_weight,
		sample_weight
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

	position = (
		idle_offset
		+ movement_offset
		+ Vector3.UP * _landing_offset_y
		+ _kick_position
		+ _shake_position
	)

	rotation = Vector3(
		_current_look_pitch_rad,
		0.0,
		_current_strafe_roll_rad + _current_look_roll_rad
	) + _kick_rotation_rad + _shake_rotation_rad
	
	
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
	
	_kick_position = Vector3.ZERO
	_kick_rotation_rad = Vector3.ZERO
	_kick_hold_remaining_s = 0.0
	_kick_return_speed = 0.0

	_shake_remaining_s = 0.0
	_shake_duration_s = 0.0
	_shake_frequency_hz = 0.0
	_shake_sample_elapsed_s = 0.0
	_shake_position_amplitude_m = Vector3.ZERO
	_shake_rotation_amplitude_rad = Vector3.ZERO
	_shake_position_target = Vector3.ZERO
	_shake_rotation_target_rad = Vector3.ZERO
	_shake_position = Vector3.ZERO
	_shake_rotation_rad = Vector3.ZERO
	
	camera.fov = _base_fov_deg
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	

func _get_owner_max_health() -> float:
	var health_component: HealthComponent = (
		_body.get_node_or_null("HealthComponent")
		as HealthComponent
	)

	if health_component == null:
		return 0.0

	return health_component.get_max_health()


func _get_local_damage_push_direction(
	world_hit_direction: Vector3
) -> Vector3:
	var world_push_direction: Vector3 = world_hit_direction
	world_push_direction.y = 0.0

	if world_push_direction.length_squared() <= 0.0001:
		return Vector3.BACK

	world_push_direction = world_push_direction.normalized()

	var local_push_direction: Vector3 = (
		_body.global_transform.basis.inverse()
		* world_push_direction
	)
	local_push_direction.y = 0.0

	if local_push_direction.length_squared() <= 0.0001:
		return Vector3.BACK

	return local_push_direction.normalized()
	
	
func _to_radians(degrees: Vector3) -> Vector3:
	return Vector3(
		deg_to_rad(degrees.x),
		deg_to_rad(degrees.y),
		deg_to_rad(degrees.z)
	)


func _max_vector_components(
	first: Vector3,
	second: Vector3
) -> Vector3:
	return Vector3(
		maxf(first.x, second.x),
		maxf(first.y, second.y),
		maxf(first.z, second.z)
	)
	

func _get_smoothing_weight(response_speed: float, delta: float) -> float:
	return 1.0 - exp(-response_speed * delta)
