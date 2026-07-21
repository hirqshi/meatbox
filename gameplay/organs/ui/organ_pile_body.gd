class_name OrganPileBody
extends RigidBody2D

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

var _organ: OrganInstance
var _organ_size_px: Vector2 = Vector2.ONE
var _pile: OrganPile


func setup(
	organ: OrganInstance,
	organ_size_px: Vector2,
	gravity_px_per_s2: float,
	pile: OrganPile
) -> void:
	assert(organ != null, "OrganPileBody requires OrganInstance.")
	assert(organ.definition != null, "OrganPileBody requires OrganDefinition.")
	assert(pile != null, "OrganPileBody requires OrganPile.")

	_organ = organ
	_pile = pile

	gravity_scale = gravity_px_per_s2 / 980.0
	lock_rotation = false
	linear_damp = 1.5
	angular_damp = 1.0
	freeze = false
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	input_pickable = true

	set_body_size(organ_size_px)


func get_organ() -> OrganInstance:
	return _organ


func set_body_size(value: Vector2) -> void:
	_organ_size_px = Vector2(
		maxf(value.x, 8.0),
		maxf(value.y, 8.0)
	)

	var rectangle_shape: RectangleShape2D = (
		_collision_shape.shape as RectangleShape2D
	)

	if rectangle_shape == null:
		rectangle_shape = RectangleShape2D.new()
		_collision_shape.shape = rectangle_shape

	rectangle_shape.size = _organ_size_px


func get_body_size() -> Vector2:
	return _organ_size_px
