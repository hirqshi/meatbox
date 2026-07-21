class_name OrganVisual
extends Control

@export_range(1.0, 60.0, 1.0)
var follow_speed: float = 24.0

@export_range(0.0, 1.0, 0.01)
var rotation_follow_weight: float = 0.2

@onready var _icon: TextureRect = $Icon

var _organ: OrganInstance
var _target_position: Vector2 = Vector2.ZERO
var _target_rotation: float = 0.0
var _current_rotation: float = 0.0
var _is_following: bool = false


func setup(organ: OrganInstance, organ_size_px: Vector2) -> void:
	assert(organ != null, "OrganVisual requires OrganInstance.")
	assert(organ.definition != null, "OrganVisual requires OrganDefinition.")

	_organ = organ
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = false

	_icon.texture = organ.definition.icon
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_SCALE

	var organ_color: Color = organ.definition.grid_tint
	if organ_color.a <= 0.01:
		organ_color.a = 1.0

	_icon.modulate = organ_color
	set_visual_size(organ_size_px)


func get_organ() -> OrganInstance:
	return _organ


func set_visual_size(organ_size_px: Vector2) -> void:
	size = Vector2(
		maxf(organ_size_px.x, 8.0),
		maxf(organ_size_px.y, 8.0)
	)

	if is_instance_valid(_icon):
		_icon.position = Vector2.ZERO
		_icon.size = size
		_icon.custom_minimum_size = Vector2.ZERO
		_icon.anchor_left = 0.0
		_icon.anchor_top = 0.0
		_icon.anchor_right = 0.0
		_icon.anchor_bottom = 0.0
		_icon.offset_left = 0.0
		_icon.offset_top = 0.0
		_icon.offset_right = size.x
		_icon.offset_bottom = size.y
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_SCALE

	pivot_offset = size * 0.5


func snap_to_global_center_position(
	global_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	global_position = global_center_position - size * 0.5
	rotation = rotation_radians
	_current_rotation = rotation_radians
	_target_position = position
	_target_rotation = rotation_radians
	_is_following = false


func snap_to_overlay_position(
	overlay_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	position = overlay_center_position - size * 0.5
	rotation = rotation_radians
	_current_rotation = rotation_radians
	_target_position = position
	_target_rotation = rotation_radians
	_is_following = false


func follow_overlay_position(
	overlay_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	_target_position = overlay_center_position - size * 0.5
	_target_rotation = rotation_radians
	_is_following = true


func _process(delta: float) -> void:
	if not _is_following:
		return

	var weight: float = clampf(follow_speed * delta, 0.0, 1.0)

	position = position.lerp(_target_position, weight)
	_current_rotation = lerp_angle(
		_current_rotation,
		_target_rotation,
		clampf(weight * rotation_follow_weight * 8.0, 0.0, 1.0)
	)
	rotation = _current_rotation
