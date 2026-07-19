class_name EnemyBrain
extends Node

signal contact_attack_landed(target: Damageable, damage_info: DamageInfo)

@export var definition: EnemyDefinition

var _body: CharacterBody3D
var _target_body: CharacterBody3D
var _target_damageable: Damageable
var _elapsed_game_time_s: float = 0.0
var _next_attack_time_s: float = 0.0
var _is_enabled: bool = true


func setup(
	body: CharacterBody3D,
	target_body: CharacterBody3D,
	target_damageable: Damageable
) -> void:
	assert(body != null, "EnemyBrain requires an enemy CharacterBody3D.")
	assert(target_body != null, "EnemyBrain requires a target CharacterBody3D.")
	assert(target_damageable != null, "EnemyBrain requires a target Damageable.")
	assert(definition != null, "EnemyBrain requires an EnemyDefinition.")
	assert(
		definition.is_valid(),
		"Invalid enemy definition '%s': %s"
		% [definition.resource_path, definition.get_validation_error()]
	)

	_body = body
	_target_body = target_body
	_target_damageable = target_damageable


func set_is_enabled(value: bool) -> void:
	_is_enabled = value

	if not _is_enabled and _body != null:
		_body.velocity = Vector3.ZERO


func physics_update(delta: float) -> void:
	if not _is_enabled:
		return

	if _body == null or _target_body == null or _target_damageable == null:
		return

	if not is_instance_valid(_target_body):
		return

	_elapsed_game_time_s += delta

	var distance_to_target_m: float = _get_flat_distance_to_target_m()

	if distance_to_target_m > definition.detection_range_m:
		_stop_horizontal_movement(delta)
		_apply_gravity(delta)
		_body.move_and_slide()
		return

	if distance_to_target_m <= definition.contact_range_m:
		_stop_horizontal_movement(delta)
		_try_contact_attack()
	else:
		_move_toward_target(delta)

	_apply_gravity(delta)
	_body.move_and_slide()


func _move_toward_target(delta: float) -> void:
	var direction_to_target: Vector3 = _get_flat_direction_to_target()
	var target_velocity: Vector3 = direction_to_target * definition.move_speed_mps

	_body.velocity.x = move_toward(
		_body.velocity.x,
		target_velocity.x,
		definition.acceleration_mps2 * delta
	)
	_body.velocity.z = move_toward(
		_body.velocity.z,
		target_velocity.z,
		definition.acceleration_mps2 * delta
	)

	if not direction_to_target.is_zero_approx():
		_body.look_at(
			_body.global_position + direction_to_target,
			Vector3.UP,
			true
		)


func _stop_horizontal_movement(delta: float) -> void:
	_body.velocity.x = move_toward(
		_body.velocity.x,
		0.0,
		definition.deceleration_mps2 * delta
	)
	_body.velocity.z = move_toward(
		_body.velocity.z,
		0.0,
		definition.deceleration_mps2 * delta
	)


func _apply_gravity(delta: float) -> void:
	if _body.is_on_floor():
		if _body.velocity.y < 0.0:
			_body.velocity.y = -0.5
		return

	_body.velocity.y -= definition.gravity_mps2 * delta


func _try_contact_attack() -> void:
	if _elapsed_game_time_s < _next_attack_time_s:
		return

	var attack_direction: Vector3 = _get_flat_direction_to_target()
	var damage_info: DamageInfo = DamageInfo.new(
		definition.contact_damage,
		_body,
		_target_body.global_position,
		Vector3.UP,
		attack_direction,
		definition.enemy_id
	)

	_target_damageable.receive_damage(damage_info)
	_next_attack_time_s = _elapsed_game_time_s + definition.contact_attack_interval_s

	contact_attack_landed.emit(_target_damageable, damage_info)


func _get_flat_distance_to_target_m() -> float:
	var offset: Vector3 = _target_body.global_position - _body.global_position
	offset.y = 0.0
	return offset.length()


func _get_flat_direction_to_target() -> Vector3:
	var direction: Vector3 = _target_body.global_position - _body.global_position
	direction.y = 0.0
	return direction.normalized()
