class_name OrganPileItem
extends RigidBody2D

signal world_drop_requested(
	organ: OrganInstance,
	screen_position: Vector2
)

@onready var _icon: Sprite2D = $Icon
@onready var _collision_shape: CollisionShape2D = (
	$CollisionShape2D
)
@onready var _drag_handle: OrganPileDragHandle = (
	$DragHandle
)

var _organ: OrganInstance
var _organ_size_px: Vector2 = Vector2.ONE


func setup(
	organ: OrganInstance,
	organ_size_px: Vector2,
	gravity_px_per_s2: float
) -> void:
	assert(
		organ != null,
		"OrganPileItem requires an OrganInstance."
	)
	assert(
		organ.definition != null,
		"OrganPileItem requires an OrganDefinition."
	)

	_organ = organ
	gravity_scale = gravity_px_per_s2 / 980.0
	lock_rotation = false
	linear_damp = 1.5
	angular_damp = 1.0

	_icon.texture = _organ.definition.icon
	_icon.modulate = _organ.definition.grid_tint

	_drag_handle.drag_started.connect(_on_drag_started)
	_drag_handle.drag_finished.connect(_on_drag_finished)

	set_organ_size_px(organ_size_px)


func get_organ() -> OrganInstance:
	return _organ


func get_organ_size_px() -> Vector2:
	return _organ_size_px


func set_organ_size_px(value: Vector2) -> void:
	_organ_size_px = Vector2(
		maxf(value.x, 8.0),
		maxf(value.y, 8.0)
	)

	_update_icon_scale()
	_update_collision_shape()
	_update_drag_handle()


func begin_drag() -> void:
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	visible = false
	_drag_handle.mouse_filter = Control.MOUSE_FILTER_IGNORE


func end_drag(was_successful: bool) -> void:
	if not is_instance_valid(self):
		return

	if was_successful:
		if not visible:
			visible = true

		freeze = false
		_drag_handle.mouse_filter = Control.MOUSE_FILTER_STOP
		return

	freeze = false
	visible = true
	_drag_handle.mouse_filter = Control.MOUSE_FILTER_STOP

	world_drop_requested.emit(
		_organ,
		get_viewport().get_mouse_position()
	)


func _update_icon_scale() -> void:
	if _icon.texture == null:
		return

	var texture_size: Vector2 = _icon.texture.get_size()

	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	_icon.scale = Vector2(
		_organ_size_px.x / texture_size.x,
		_organ_size_px.y / texture_size.y
	)


func _update_collision_shape() -> void:
	var rectangle_shape: RectangleShape2D = (
		_collision_shape.shape
		as RectangleShape2D
	)

	if rectangle_shape == null:
		rectangle_shape = RectangleShape2D.new()
		_collision_shape.shape = rectangle_shape

	rectangle_shape.size = _organ_size_px


func _update_drag_handle() -> void:
	_drag_handle.position = -_organ_size_px * 0.5
	_drag_handle.size = _organ_size_px
	_drag_handle.mouse_filter = Control.MOUSE_FILTER_STOP
	_drag_handle.z_index = 100


func _on_drag_started() -> void:
	begin_drag()


func _on_drag_finished(
	was_successful: bool
) -> void:
	end_drag(was_successful)
