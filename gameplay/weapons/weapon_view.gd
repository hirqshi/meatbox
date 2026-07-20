class_name WeaponView
extends Node3D

enum EquipState {
	HIDDEN,
	EQUIPPING,
	VISIBLE,
	HOLSTERING,
}

@onready var _motion_offset: Node3D = $MotionOffset
@onready var _recoil_offset: Node3D = (
	$MotionOffset/RecoilOffset
)
@onready var _equip_offset: Node3D = (
	$MotionOffset/RecoilOffset/EquipOffset
)
@onready var _visual: AnimatedSprite3D = (
	$MotionOffset/RecoilOffset/EquipOffset/Visual
)

var _weapon_controller: WeaponController
var _combat: PlayerCombat
var _body: CharacterBody3D

var _active_weapon: WeaponInstance
var _pending_weapon: WeaponInstance
var _presentation: WeaponPresentationDefinition

var _equip_state: EquipState = EquipState.HIDDEN
var _equip_elapsed_s: float = 0.0
var _equip_duration_s: float = 0.0
var _equip_start_position: Vector3 = Vector3.ZERO
var _equip_target_position: Vector3 = Vector3.ZERO

var _idle_phase: float = 0.0
var _move_phase: float = 0.0
var _movement_bob_weight: float = 0.0

var _current_motion_position: Vector3 = Vector3.ZERO
var _current_motion_rotation_rad: Vector3 = Vector3.ZERO

var _look_roll_target_rad: float = 0.0
var _look_pitch_target_rad: float = 0.0
var _current_look_roll_rad: float = 0.0
var _current_look_pitch_rad: float = 0.0

var _landing_offset_y: float = 0.0
var _landing_target_offset_y: float = 0.0
var _landing_velocity_y: float = 0.0

var _recoil_position: Vector3 = Vector3.ZERO
var _recoil_rotation_rad: Vector3 = Vector3.ZERO
var _shake_remaining_s: float = 0.0

var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_visual.animation_finished.connect(
		_on_visual_animation_finished
	)

	_visual.visible = false


func setup(
	weapon_controller: WeaponController,
	combat: PlayerCombat,
	body: CharacterBody3D
) -> void:
	assert(
		weapon_controller != null,
		"WeaponView requires a WeaponController."
	)
	assert(
		combat != null,
		"WeaponView requires a PlayerCombat."
	)
	assert(
		body != null,
		"WeaponView requires a CharacterBody3D."
	)

	_disconnect_signals()

	_weapon_controller = weapon_controller
	_combat = combat
	_body = body

	_weapon_controller.active_weapon_changed.connect(
		_on_active_weapon_changed
	)
	_weapon_controller.weapon_reload_started.connect(
		_on_weapon_reload_started
	)
	_weapon_controller.weapon_reload_finished.connect(
		_on_weapon_reload_finished
	)
	_weapon_controller.weapon_reload_cancelled.connect(
		_on_weapon_reload_cancelled
	)

	_combat.weapon_fired.connect(_on_weapon_fired)

	_request_weapon_change(
		_weapon_controller.get_active_weapon()
	)


func physics_update(delta: float) -> void:
	if _body == null or _presentation == null:
		return

	_update_equip_transition(delta)
	_update_motion(delta)
	_update_recoil(delta)


func register_look_delta(mouse_delta: Vector2) -> void:
	if _presentation == null:
		return

	_look_roll_target_rad = clampf(
		-mouse_delta.x
		* _presentation.mouse_delta_to_inertia,
		-deg_to_rad(_presentation.yaw_inertia_roll_deg),
		deg_to_rad(_presentation.yaw_inertia_roll_deg)
	)

	_look_pitch_target_rad = clampf(
		mouse_delta.y
		* _presentation.mouse_delta_to_inertia,
		-deg_to_rad(_presentation.pitch_inertia_pitch_deg),
		deg_to_rad(_presentation.pitch_inertia_pitch_deg)
	)


func register_landing(
	fall_speed_mps: float,
	_horizontal_speed_mps: float
) -> void:
	if _presentation == null:
		return

	var landing_speed_ratio: float = clampf(
		fall_speed_mps
		/ _presentation.max_landing_speed_mps,
		0.0,
		1.0
	)

	var landing_drop_m: float = (
		_presentation.landing_offset_m
		* landing_speed_ratio
	)

	if landing_drop_m <= 0.0:
		return

	_landing_target_offset_y = minf(
		_landing_target_offset_y - landing_drop_m,
		-_presentation.landing_offset_m
	)


func _request_weapon_change(
	weapon: WeaponInstance
) -> void:
	if weapon == _active_weapon:
		return

	_pending_weapon = weapon

	if _active_weapon == null:
		_apply_pending_weapon()
		_begin_equip()
		return

	_begin_holster()


func _apply_pending_weapon() -> void:
	_active_weapon = _pending_weapon
	_pending_weapon = null

	if _active_weapon == null:
		_presentation = null
		_visual.visible = false
		_equip_state = EquipState.HIDDEN
		return

	_presentation = _active_weapon.definition.view_presentation

	if _presentation == null:
		_visual.visible = false
		_equip_state = EquipState.HIDDEN
		return

	_visual.visible = true
	_visual.sprite_frames = _presentation.sprite_frames
	_visual.position = Vector3.ZERO
	_visual.rotation = Vector3.ZERO
	_visual.scale = Vector3.ONE * _presentation.view_scale

	_equip_offset.position = _get_hidden_position()
	_equip_offset.rotation_degrees = (
		_presentation.view_rotation_degrees
	)

	_play_default_animation()


func _begin_equip() -> void:
	if _presentation == null:
		return

	_begin_equip_transition(
		_get_hidden_position(),
		_get_visible_position(),
		_presentation.equip_duration_s,
		EquipState.EQUIPPING
	)


func _begin_holster() -> void:
	if _presentation == null:
		_apply_pending_weapon()
		_begin_equip()
		return

	_begin_equip_transition(
		_equip_offset.position,
		_get_hidden_position(),
		_presentation.unequip_duration_s,
		EquipState.HOLSTERING
	)


func _begin_equip_transition(
	start_position: Vector3,
	target_position: Vector3,
	duration_s: float,
	next_state: EquipState
) -> void:
	_equip_start_position = start_position
	_equip_target_position = target_position
	_equip_duration_s = maxf(duration_s, 0.01)
	_equip_elapsed_s = 0.0
	_equip_state = next_state


func _update_equip_transition(delta: float) -> void:
	if _equip_state != EquipState.EQUIPPING:
		if _equip_state != EquipState.HOLSTERING:
			return

	_equip_elapsed_s += delta

	var progress: float = clampf(
		_equip_elapsed_s / _equip_duration_s,
		0.0,
		1.0
	)

	var eased_progress: float = ease(progress, -2.0)

	_equip_offset.position = _equip_start_position.lerp(
		_equip_target_position,
		eased_progress
	)

	if progress < 1.0:
		return

	if _equip_state == EquipState.HOLSTERING:
		_apply_pending_weapon()

		if _presentation == null:
			return

		_begin_equip()
		return

	_equip_state = EquipState.VISIBLE


func _update_motion(delta: float) -> void:
	var horizontal_speed_mps: float = Vector2(
		_body.velocity.x,
		_body.velocity.z
	).length()

	var speed_ratio: float = clampf(
		horizontal_speed_mps / 10.0,
		0.0,
		1.0
	)

	_idle_phase += (
		TAU
		* _presentation.idle_bob_frequency_hz
		* delta
	)

	if _body.is_on_floor():
		if speed_ratio >= _presentation.minimum_bob_speed_ratio:
			var move_frequency_hz: float = (
				_presentation.move_bob_base_frequency_hz
				+ _presentation.move_bob_speed_frequency_hz
				* speed_ratio
			)

			_move_phase += TAU * move_frequency_hz * delta

	var target_bob_weight: float = 0.0

	if _body.is_on_floor():
		target_bob_weight = smoothstep(
			_presentation.minimum_bob_speed_ratio,
			1.0,
			speed_ratio
		)

	_movement_bob_weight = lerpf(
		_movement_bob_weight,
		target_bob_weight,
		_get_smoothing_weight(
			_presentation.motion_response_speed,
			delta
		)
	)

	_update_landing_spring(delta)

	var idle_offset: Vector3 = Vector3(
		cos(_idle_phase)
		* _presentation.idle_bob_horizontal_m,
		sin(_idle_phase)
		* _presentation.idle_bob_vertical_m,
		0.0
	)

	var move_offset: Vector3 = Vector3(
		cos(_move_phase)
		* _presentation.move_bob_horizontal_m
		* _movement_bob_weight,
		absf(sin(_move_phase))
		* _presentation.move_bob_vertical_m
		* _movement_bob_weight,
		0.0
	)

	var strafe_input: float = Input.get_axis(
		&"move_left",
		&"move_right"
	)

	var vertical_velocity_ratio: float = clampf(
		_body.velocity.y
		/ _presentation.vertical_tilt_max_speed_mps,
		-1.0,
		1.0
	)

	var target_position: Vector3 = (
		idle_offset
		+ move_offset
		+ Vector3.UP * _landing_offset_y
	)

	var target_rotation_rad: Vector3 = Vector3(
		deg_to_rad(
			_presentation.vertical_velocity_tilt_deg
			* vertical_velocity_ratio
		)
		+ _current_look_pitch_rad,
		0.0,
		deg_to_rad(
			-_presentation.strafe_tilt_deg
			* strafe_input
		)
		+ _current_look_roll_rad
	)

	var response_weight: float = _get_smoothing_weight(
		_presentation.motion_response_speed,
		delta
	)

	_current_motion_position = _current_motion_position.lerp(
		target_position,
		response_weight
	)

	_current_motion_rotation_rad = (
		_current_motion_rotation_rad.lerp(
			target_rotation_rad,
			response_weight
		)
	)

	_current_look_roll_rad = lerpf(
		_current_look_roll_rad,
		_look_roll_target_rad,
		_get_smoothing_weight(
			_presentation.look_inertia_response_speed,
			delta
		)
	)

	_current_look_pitch_rad = lerpf(
		_current_look_pitch_rad,
		_look_pitch_target_rad,
		_get_smoothing_weight(
			_presentation.look_inertia_response_speed,
			delta
		)
	)

	_look_roll_target_rad = lerpf(
		_look_roll_target_rad,
		0.0,
		_get_smoothing_weight(
			_presentation.look_inertia_response_speed,
			delta
		)
	)

	_look_pitch_target_rad = lerpf(
		_look_pitch_target_rad,
		0.0,
		_get_smoothing_weight(
			_presentation.look_inertia_response_speed,
			delta
		)
	)

	_motion_offset.position = _current_motion_position
	_motion_offset.rotation = _current_motion_rotation_rad


func _update_landing_spring(delta: float) -> void:
	var response_weight: float = _get_smoothing_weight(
		_presentation.landing_impact_response_speed,
		delta
	)

	_landing_target_offset_y = lerpf(
		_landing_target_offset_y,
		0.0,
		response_weight
	)

	var acceleration_y: float = (
		(_landing_target_offset_y - _landing_offset_y)
		* _presentation.landing_spring_strength
		- _landing_velocity_y
		* _presentation.landing_spring_damping
	)

	_landing_velocity_y += acceleration_y * delta
	_landing_offset_y += _landing_velocity_y * delta


func _update_recoil(delta: float) -> void:
	var recoil_weight: float = _get_smoothing_weight(
		_presentation.recoil_return_speed,
		delta
	)

	_recoil_position = _recoil_position.lerp(
		Vector3.ZERO,
		recoil_weight
	)

	_recoil_rotation_rad = _recoil_rotation_rad.lerp(
		Vector3.ZERO,
		recoil_weight
	)

	var shake_position: Vector3 = Vector3.ZERO
	var shake_rotation_rad: Vector3 = Vector3.ZERO

	if _shake_remaining_s > 0.0:
		_shake_remaining_s = maxf(
			_shake_remaining_s - delta,
			0.0
		)

		var shake_weight: float = (
			_shake_remaining_s
			/ maxf(
				_presentation.fire_shake_duration_s,
				0.001
			)
		)

		shake_position = Vector3(
			_random.randf_range(-1.0, 1.0)
			* _presentation.fire_shake_position_m.x,
			_random.randf_range(-1.0, 1.0)
			* _presentation.fire_shake_position_m.y,
			_random.randf_range(-1.0, 1.0)
			* _presentation.fire_shake_position_m.z
		) * shake_weight

		shake_rotation_rad = _to_radians(
			Vector3(
				_random.randf_range(-1.0, 1.0)
				* _presentation.fire_shake_rotation_degrees.x,
				_random.randf_range(-1.0, 1.0)
				* _presentation.fire_shake_rotation_degrees.y,
				_random.randf_range(-1.0, 1.0)
				* _presentation.fire_shake_rotation_degrees.z
			)
		) * shake_weight

	_recoil_offset.position = (
		_recoil_position
		+ shake_position
	)

	_recoil_offset.rotation = (
		_recoil_rotation_rad
		+ shake_rotation_rad
	)


func _on_active_weapon_changed(
	_active_slot_index: int,
	weapon: WeaponInstance
) -> void:
	_request_weapon_change(weapon)


func _on_weapon_fired(
	weapon: WeaponInstance
) -> void:
	if weapon != _active_weapon:
		return

	if _presentation == null:
		return

	if _equip_state != EquipState.VISIBLE:
		return

	_recoil_position += _presentation.fire_kick_position_m
	_recoil_rotation_rad += _to_radians(
		_presentation.fire_kick_rotation_degrees
	)
	_shake_remaining_s = _presentation.fire_shake_duration_s

	_play_animation(
		_presentation.fire_animation_name,
		true
	)


func _on_weapon_reload_started(
	weapon: WeaponInstance
) -> void:
	if weapon != _active_weapon:
		return

	if _presentation == null:
		return

	_play_animation(
		_presentation.reload_animation_name,
		true
	)


func _on_weapon_reload_finished(
	weapon: WeaponInstance
) -> void:
	if weapon != _active_weapon:
		return

	_play_default_animation()


func _on_weapon_reload_cancelled(
	weapon: WeaponInstance
) -> void:
	if weapon != _active_weapon:
		return

	_play_default_animation()


func _on_visual_animation_finished() -> void:
	if _active_weapon == null:
		return

	if _active_weapon.is_reloading:
		return

	_play_default_animation()


func _play_default_animation() -> void:
	if _presentation == null:
		return

	_play_animation(
		_presentation.default_animation_name,
		true
	)


func _play_animation(
	animation_name: StringName,
	restart: bool
) -> void:
	if _visual.sprite_frames == null:
		return

	if not _visual.sprite_frames.has_animation(
		animation_name
	):
		return

	if restart:
		_visual.stop()
		_visual.frame = 0

	_visual.play(animation_name)


func _get_visible_position() -> Vector3:
	return _presentation.view_offset


func _get_hidden_position() -> Vector3:
	return (
		_presentation.view_offset
		+ _presentation.hidden_offset
	)


func _get_smoothing_weight(
	response_speed: float,
	delta: float
) -> float:
	return 1.0 - exp(-response_speed * delta)


func _to_radians(
	degrees: Vector3
) -> Vector3:
	return Vector3(
		deg_to_rad(degrees.x),
		deg_to_rad(degrees.y),
		deg_to_rad(degrees.z)
	)


func _disconnect_signals() -> void:
	if _weapon_controller != null:
		if _weapon_controller.active_weapon_changed.is_connected(
			_on_active_weapon_changed
		):
			_weapon_controller.active_weapon_changed.disconnect(
				_on_active_weapon_changed
			)

		if _weapon_controller.weapon_reload_started.is_connected(
			_on_weapon_reload_started
		):
			_weapon_controller.weapon_reload_started.disconnect(
				_on_weapon_reload_started
			)

		if _weapon_controller.weapon_reload_finished.is_connected(
			_on_weapon_reload_finished
		):
			_weapon_controller.weapon_reload_finished.disconnect(
				_on_weapon_reload_finished
			)

		if _weapon_controller.weapon_reload_cancelled.is_connected(
			_on_weapon_reload_cancelled
		):
			_weapon_controller.weapon_reload_cancelled.disconnect(
				_on_weapon_reload_cancelled
			)

	if _combat != null:
		if _combat.weapon_fired.is_connected(
			_on_weapon_fired
		):
			_combat.weapon_fired.disconnect(
				_on_weapon_fired
			)
