class_name PlayerMotor
extends Node

@export var definition: PlayerDefinition

var _body: CharacterBody3D
var _is_enabled: bool = true


func setup(body: CharacterBody3D) -> void:
	assert(body != null, "PlayerMotor requires a CharacterBody3D.")
	assert(definition != null, "PlayerMotor requires a PlayerDefinition.")
	assert(definition.validate(), "PlayerDefinition contains invalid values.")

	_body = body


func set_is_enabled(value: bool) -> void:
	_is_enabled = value

	if not _is_enabled and _body != null:
		_body.velocity = Vector3.ZERO


func physics_update(delta: float) -> void:
	if not _is_enabled or _body == null or definition == null:
		return

	_apply_vertical_movement(delta)
	_apply_horizontal_movement(delta)
	_body.move_and_slide()


func _apply_vertical_movement(delta: float) -> void:
	if _body.is_on_floor():
		if Input.is_action_just_pressed(&"jump"):
			_body.velocity.y = definition.jump_velocity_mps
		elif _body.velocity.y < 0.0:
			_body.velocity.y = -definition.ground_stick_velocity_mps
		return

	_body.velocity.y -= definition.gravity_mps2 * delta


func _apply_horizontal_movement(delta: float) -> void:
	var input_vector: Vector2 = Input.get_vector(
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

	var target_velocity: Vector3 = world_direction * definition.run_speed_mps
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
