class_name PlayerMotor
extends Node

signal landed(
	fall_speed_mps: float,
	horizontal_speed_mps: float
)

@export var definition: PlayerDefinition

var _body: CharacterBody3D
var _is_enabled: bool = true
var _was_on_floor: bool = false
var _jump_buffer_remaining_s: float = 0.0
var _stat_modifiers: PlayerStatModifiers


func setup(body: CharacterBody3D) -> void:
	assert(body != null, "PlayerMotor requires a CharacterBody3D.")
	assert(definition != null, "PlayerMotor requires a PlayerDefinition.")
	assert(definition.validate(), "PlayerDefinition contains invalid values.")

	_body = body
	_was_on_floor = _body.is_on_floor()


func set_stat_modifiers(
	stat_modifiers: PlayerStatModifiers
) -> void:
	_stat_modifiers = stat_modifiers


func set_is_enabled(value: bool) -> void:
	_is_enabled = value

	if not _is_enabled and _body != null:
		_body.velocity = Vector3.ZERO
		_jump_buffer_remaining_s = 0.0


func handle_input(event: InputEvent) -> void:
	if not _is_enabled or definition == null:
		return

	if event.is_action_pressed(&"jump"):
		_jump_buffer_remaining_s = definition.jump_buffer_duration_s


func physics_update(delta: float) -> void:
	if not _is_enabled or _body == null or definition == null:
		return

	var vertical_speed_before_move_mps: float = _body.velocity.y

	_update_jump_buffer(delta)
	_apply_vertical_movement(delta)
	_apply_horizontal_movement(delta)
	var horizontal_speed_before_move_mps: float = Vector2(
	_body.velocity.x,
	_body.velocity.z
	).length()
	_body.move_and_slide()

	var has_landed: bool = not _was_on_floor and _body.is_on_floor()

	if has_landed:
		landed.emit(
		maxf(-vertical_speed_before_move_mps, 0.0),
		horizontal_speed_before_move_mps
		)

	_was_on_floor = _body.is_on_floor()


func _update_jump_buffer(delta: float) -> void:
	_jump_buffer_remaining_s = maxf(
		_jump_buffer_remaining_s - delta,
		0.0
	)


func _apply_vertical_movement(delta: float) -> void:
	if _body.is_on_floor():
		if (
			not DeveloperConsole.is_open()
			and _jump_buffer_remaining_s > 0.0
		):
			_body.velocity.y = (
				definition.jump_velocity_mps
				+ _get_jump_velocity_bonus_m_per_s()
			)
			_jump_buffer_remaining_s = 0.0
		elif _body.velocity.y < 0.0:
			_body.velocity.y = (
				-definition.ground_stick_velocity_mps
			)

		return

	_body.velocity.y -= definition.gravity_mps2 * delta


func _apply_horizontal_movement(delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO

	if not DeveloperConsole.is_open():
		input_vector = Input.get_vector(
			&"move_left",
			&"move_right",
			&"move_forward",
			&"move_backward"
		)

	var local_direction: Vector3 = Vector3(
		input_vector.x,
		0.0,
		input_vector.y
	)

	var world_direction: Vector3 = _body.global_transform.basis * local_direction
	world_direction.y = 0.0
	world_direction = world_direction.normalized()

	var target_velocity: Vector3 = (
	world_direction
	* (
		definition.run_speed_mps
		+ _get_move_speed_bonus_m_per_s()
	)
	)
	var acceleration: float = definition.ground_acceleration_mps2

	if not _body.is_on_floor():
		acceleration *= definition.air_control_multiplier

	if world_direction.is_zero_approx():
		_body.velocity.x = move_toward(
			_body.velocity.x,
			0.0,
			definition.ground_deceleration_mps2 * delta
		)
		_body.velocity.z = move_toward(
			_body.velocity.z,
			0.0,
			definition.ground_deceleration_mps2 * delta
		)
		return

	_body.velocity.x = move_toward(
		_body.velocity.x,
		target_velocity.x,
		acceleration * delta
	)
	_body.velocity.z = move_toward(
		_body.velocity.z,
		target_velocity.z,
		acceleration * delta
	)

func _get_move_speed_bonus_m_per_s() -> float:
	if _stat_modifiers == null:
		return 0.0

	return _stat_modifiers.get_move_speed_bonus_m_per_s()


func _get_jump_velocity_bonus_m_per_s() -> float:
	if _stat_modifiers == null:
		return 0.0

	return _stat_modifiers.get_jump_velocity_bonus_m_per_s()
	
