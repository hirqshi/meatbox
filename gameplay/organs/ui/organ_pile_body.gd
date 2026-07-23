class_name OrganPileBody
extends RigidBody2D

signal teleport_applied

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _organ: OrganInstance
var _logical_size_px: Vector2 = Vector2.ONE
var _collision_size_px: Vector2 = Vector2.ONE
var _global_collision_scale: float = 1.0
var _pile: OrganPile

var _has_pending_teleport: bool = false
var _pending_global_position: Vector2 = Vector2.ZERO
var _pending_rotation: float = 0.0
var _pending_linear_velocity: Vector2 = Vector2.ZERO
var _pending_angular_velocity: float = 0.0


func setup(
	organ: OrganInstance,
	logical_size_px: Vector2,
	gravity_px_per_s2: float,
	pile: OrganPile,
	global_collision_scale: float = 1.0
) -> void:
	assert(organ != null, "OrganPileBody requires OrganInstance.")
	assert(organ.definition != null, "OrganPileBody requires OrganDefinition.")
	assert(pile != null, "OrganPileBody requires OrganPile.")

	_organ = organ
	_pile = pile
	_global_collision_scale = maxf(global_collision_scale, 0.1)

	gravity_scale = gravity_px_per_s2 / 980.0
	lock_rotation = false
	linear_damp = 1.5
	angular_damp = 1.0
	freeze = false
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	input_pickable = true

	set_body_size(logical_size_px)


func get_organ() -> OrganInstance:
	return _organ


func set_global_collision_scale(value: float) -> void:
	_global_collision_scale = maxf(value, 0.1)
	set_body_size(_logical_size_px)


func set_body_size(logical_size_px: Vector2) -> void:
	_logical_size_px = Vector2(
		maxf(logical_size_px.x, 8.0),
		maxf(logical_size_px.y, 8.0)
	)

	var local_collision_scale: float = 1.0
	if _organ != null and _organ.definition != null:
		local_collision_scale = _organ.definition.get_collision_scale()

	_collision_size_px = (
		_logical_size_px
		* _global_collision_scale
		* local_collision_scale
	)

	var rectangle_shape: RectangleShape2D = (
		_collision_shape.shape as RectangleShape2D
	)

	if rectangle_shape == null:
		rectangle_shape = RectangleShape2D.new()
		_collision_shape.shape = rectangle_shape

	rectangle_shape.size = _collision_size_px


func get_body_size() -> Vector2:
	return _collision_size_px


func get_logical_size() -> Vector2:
	return _logical_size_px


func teleport_and_release(
	target_position: Vector2,
	target_rotation_radians: float,
	release_linear_velocity: Vector2,
	release_angular_velocity: float
) -> void:
	_pending_global_position = target_position
	_pending_rotation = target_rotation_radians
	_pending_linear_velocity = release_linear_velocity
	_pending_angular_velocity = release_angular_velocity
	_has_pending_teleport = true

	position = target_position
	rotation = target_rotation_radians
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	sleeping = false
	freeze = false


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not _has_pending_teleport:
		return

	state.transform = Transform2D(_pending_rotation, _pending_global_position)
	state.linear_velocity = _pending_linear_velocity
	state.angular_velocity = _pending_angular_velocity
	state.sleeping = false

	_has_pending_teleport = false
	teleport_applied.emit()
