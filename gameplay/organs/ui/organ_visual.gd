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

	_kill_tween(_shake_tween)

	var origin: Vector2 = position
	var duration_sec: float = visual_definition.click_shake_duration_sec
	var offset_px: float = visual_definition.click_shake_offset_px

	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_SINE)
	_shake_tween.set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(
		self,
		"position",
		origin + Vector2(offset_px, 0.0),
		duration_sec * 0.33
	)
	_shake_tween.tween_property(
		self,
		"position",
		origin + Vector2(-offset_px * 0.7, 0.0),
		duration_sec * 0.33
	)
	_shake_tween.tween_property(
		self,
		"position",
		origin,
		duration_sec * 0.34
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
