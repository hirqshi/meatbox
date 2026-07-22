class_name OrganVisual
extends Control

@export_range(0.1, 8.0, 0.01)
var global_icon_scale: float = 1.0

@onready var _icon: TextureRect = $Icon

var _organ: OrganInstance
var _logical_size_px: Vector2 = Vector2(8.0, 8.0)
var _visual_size_px: Vector2 = Vector2(8.0, 8.0)
var _is_hovered: bool = false

var _move_tween: Tween
var _scale_tween: Tween
var _shake_tween: Tween

var _icon_rest_position: Vector2 = Vector2.ZERO
var _icon_rest_rotation: float = 0.0

var _shake_primary_offset_px: float = 0.0
var _shake_secondary_offset_px: float = 0.0
var _shake_primary_axis: Vector2 = Vector2.RIGHT
var _shake_secondary_axis: Vector2 = Vector2.DOWN
var _shake_frequency_hz: float = 0.0
var _shake_secondary_frequency_hz: float = 0.0
var _shake_rotation_radians: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = false

	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_layout()


func setup(organ: OrganInstance, logical_size_px: Vector2) -> void:
	assert(organ != null, "OrganVisual requires OrganInstance.")
	assert(organ.definition != null, "OrganVisual requires OrganDefinition.")

	_organ = organ
	_apply_definition_visuals()
	set_logical_size(logical_size_px)


func get_organ() -> OrganInstance:
	return _organ


func set_global_icon_scale(value: float) -> void:
	global_icon_scale = maxf(value, 0.1)
	_refresh_visual_size()
	_apply_layout()


func set_logical_size(logical_size_px: Vector2) -> void:
	_logical_size_px = Vector2(
		maxf(logical_size_px.x, 8.0),
		maxf(logical_size_px.y, 8.0)
	)

	_refresh_visual_size()
	_apply_layout()


func get_logical_size() -> Vector2:
	return _logical_size_px


func get_visual_size() -> Vector2:
	return _visual_size_px


func snap_to_global_center_position(
	global_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	_kill_tween(_move_tween)

	global_position = global_center_position - size * 0.5
	rotation = rotation_radians


func snap_to_overlay_position(
	overlay_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	_kill_tween(_move_tween)

	position = overlay_center_position - size * 0.5
	rotation = rotation_radians


func tween_to_overlay_position(
	overlay_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	_kill_tween(_move_tween)

	var target_position: Vector2 = overlay_center_position - size * 0.5
	var duration_sec: float = _get_move_duration_sec()

	_move_tween = create_tween()
	_move_tween.set_parallel(true)
	_move_tween.set_trans(Tween.TRANS_CUBIC)
	_move_tween.set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", target_position, duration_sec)
	_move_tween.tween_property(self, "rotation", rotation_radians, duration_sec)


func snap_to_local_rect_center() -> void:
	snap_to_overlay_position(size * 0.5)


func play_hover_enter() -> void:
	if _is_hovered:
		return

	_is_hovered = true
	_play_hover_scale()


func play_hover_exit() -> void:
	if not _is_hovered:
		return

	_is_hovered = false
	_play_hover_scale()


func play_click_shake() -> void:
	if _organ == null or _organ.definition == null:
		return

	var visual_definition: OrganVisualDefinition = (
		_organ.definition.visual_definition
	)

	if visual_definition == null:
		return

	_play_icon_shake(
		visual_definition.click_shake_offset_px,
		visual_definition.click_shake_secondary_offset_px,
		deg_to_rad(visual_definition.click_shake_axis_deg),
		deg_to_rad(visual_definition.click_shake_secondary_axis_deg),
		visual_definition.click_shake_frequency_hz,
		visual_definition.click_shake_secondary_frequency_hz,
		deg_to_rad(visual_definition.click_shake_rotation_deg),
		visual_definition.click_shake_duration_sec
	)


func play_insert_shake() -> void:
	if _organ == null or _organ.definition == null:
		return

	var visual_definition: OrganVisualDefinition = (
		_organ.definition.visual_definition
	)

	if visual_definition == null:
		return

	_play_icon_shake(
		visual_definition.insert_shake_offset_px,
		visual_definition.insert_shake_secondary_offset_px,
		deg_to_rad(visual_definition.insert_shake_axis_deg),
		deg_to_rad(visual_definition.insert_shake_secondary_axis_deg),
		visual_definition.insert_shake_frequency_hz,
		visual_definition.insert_shake_secondary_frequency_hz,
		deg_to_rad(visual_definition.insert_shake_rotation_deg),
		visual_definition.insert_shake_duration_sec
	)


func _apply_definition_visuals() -> void:
	if _organ == null or _organ.definition == null:
		_icon.texture = null
		_icon.modulate = Color.WHITE
		return

	var definition: OrganDefinition = _organ.definition
	var organ_color: Color = definition.grid_tint
	if organ_color.a <= 0.01:
		organ_color.a = 1.0

	if definition.visual_definition != null:
		if definition.visual_definition.tint.a > 0.01:
			organ_color *= definition.visual_definition.tint

	_icon.texture = definition.get_icon()
	_icon.modulate = organ_color


func _refresh_visual_size() -> void:
	var scale_value: float = global_icon_scale

	if _organ != null and _organ.definition != null:
		scale_value *= _organ.definition.get_visual_scale()

	_visual_size_px = _logical_size_px * scale_value


func _apply_layout() -> void:
	size = _logical_size_px
	custom_minimum_size = _logical_size_px
	pivot_offset = size * 0.5

	if not is_instance_valid(_icon):
		return

	_icon.custom_minimum_size = Vector2.ZERO
	_icon.anchor_left = 0.0
	_icon.anchor_top = 0.0
	_icon.anchor_right = 0.0
	_icon.anchor_bottom = 0.0

	_icon.size = _visual_size_px
	_icon.position = (size - _visual_size_px) * 0.5
	_icon.pivot_offset = _icon.size * 0.5
	_icon.rotation = 0.0

	_icon_rest_position = _icon.position
	_icon_rest_rotation = _icon.rotation

	_icon.offset_left = _icon.position.x
	_icon.offset_top = _icon.position.y
	_icon.offset_right = _icon.position.x + _icon.size.x
	_icon.offset_bottom = _icon.position.y + _icon.size.y


func _play_hover_scale() -> void:
	_kill_tween(_scale_tween)

	var target_scale: Vector2 = Vector2.ONE
	var duration_sec: float = 0.08

	if _organ != null and _organ.definition != null:
		var visual_definition: OrganVisualDefinition = (
			_organ.definition.visual_definition
		)

		if visual_definition != null:
			duration_sec = visual_definition.hover_duration_sec

			if _is_hovered:
				target_scale = Vector2.ONE * (
					visual_definition.hover_scale_multiplier
				)

	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", target_scale, duration_sec)


func _play_icon_shake(
	primary_offset_px: float,
	secondary_offset_px: float,
	primary_axis_radians: float,
	secondary_axis_radians: float,
	frequency_hz: float,
	secondary_frequency_hz: float,
	rotation_radians: float,
	duration_sec: float
) -> void:
	if not is_instance_valid(_icon):
		return

	_kill_tween(_shake_tween)
	_reset_icon_shake_state()

	_shake_primary_offset_px = primary_offset_px
	_shake_secondary_offset_px = secondary_offset_px
	_shake_primary_axis = Vector2.RIGHT.rotated(primary_axis_radians)
	_shake_secondary_axis = Vector2.RIGHT.rotated(secondary_axis_radians)
	_shake_frequency_hz = frequency_hz
	_shake_secondary_frequency_hz = secondary_frequency_hz
	_shake_rotation_radians = rotation_radians

	if duration_sec <= 0.0:
		return

	if (
		is_zero_approx(primary_offset_px)
		and is_zero_approx(secondary_offset_px)
		and is_zero_approx(rotation_radians)
	):
		return

	_shake_tween = create_tween()
	_shake_tween.tween_method(
		_apply_shake_sample,
		0.0,
		1.0,
		duration_sec
	)
	_shake_tween.finished.connect(_reset_icon_shake_state)


func _apply_shake_sample(progress: float) -> void:
	if not is_instance_valid(_icon):
		return

	var envelope: float = 1.0 - progress

	var primary_wave: float = sin(TAU * _shake_frequency_hz * progress)
	var secondary_wave: float = sin(
		TAU * _shake_secondary_frequency_hz * progress + PI * 0.5
	)

	var offset: Vector2 = (
		_shake_primary_axis * _shake_primary_offset_px * primary_wave
		+ _shake_secondary_axis * _shake_secondary_offset_px * secondary_wave
	) * envelope

	_icon.position = _icon_rest_position + offset
	_icon.rotation = _icon_rest_rotation + (
		_shake_rotation_radians * primary_wave * envelope
	)


func _reset_icon_shake_state() -> void:
	if not is_instance_valid(_icon):
		return

	_icon.position = _icon_rest_position
	_icon.rotation = _icon_rest_rotation


func _get_move_duration_sec() -> float:
	if _organ == null or _organ.definition == null:
		return 0.12

	var visual_definition: OrganVisualDefinition = (
		_organ.definition.visual_definition
	)

	if visual_definition == null:
		return 0.12

	return visual_definition.move_duration_sec


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
