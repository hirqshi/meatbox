class_name OrganVisual
extends Node2D

const DEBUG_DRAG_GHOST: bool = true

const DEFAULT_ANIMATION: StringName = &"default"

@export_range(0.1, 8.0, 0.01)
var global_icon_scale: float = 1.0

@onready var _pivot: Node2D = $Pivot
@onready var _sprite: AnimatedSprite2D = $Pivot/Sprite

var _organ: OrganInstance
var _logical_size_px: Vector2 = Vector2(8.0, 8.0)
var _display_base_size_px: Vector2 = Vector2(8.0, 8.0)
var _visual_size_px: Vector2 = Vector2(8.0, 8.0)
var _is_hovered: bool = false

var _position_tween: Tween
var _rotation_tween: Tween
var _scale_tween: Tween
var _shake_tween: Tween
var _sprite_rotation_tween: Tween

var _rotation_from: float = 0.0
var _rotation_to: float = 0.0

var _sprite_rest_position: Vector2 = Vector2.ZERO
var _sprite_rest_rotation: float = 0.0

var _shake_primary_offset_px: float = 0.0
var _shake_secondary_offset_px: float = 0.0
var _shake_primary_axis: Vector2 = Vector2.RIGHT
var _shake_secondary_axis: Vector2 = Vector2.DOWN
var _shake_frequency_hz: float = 0.0
var _shake_secondary_frequency_hz: float = 0.0
var _shake_rotation_radians: float = 0.0


func _ready() -> void:
	visible = true
	_pivot.scale = Vector2.ONE
	_pivot.rotation = 0.0
	_sprite.centered = true
	_sprite.position = Vector2.ZERO
	_sprite.rotation = 0.0
	_apply_definition_visuals()
	_apply_layout()


func setup(
	organ: OrganInstance,
	logical_size_px: Vector2,
	display_base_size_px: Vector2 = Vector2.ZERO
) -> void:
	assert(organ != null, "OrganVisual requires OrganInstance.")
	assert(organ.definition != null, "OrganVisual requires OrganDefinition.")

	_organ = organ
	_apply_definition_visuals()
	set_sizes(logical_size_px, display_base_size_px)


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

	if _display_base_size_px == Vector2.ZERO:
		_display_base_size_px = _logical_size_px

	_refresh_visual_size()
	_apply_layout()


func set_display_base_size(display_base_size_px: Vector2) -> void:
	_display_base_size_px = Vector2(
		maxf(display_base_size_px.x, 8.0),
		maxf(display_base_size_px.y, 8.0)
	)

	_refresh_visual_size()
	_apply_layout()


func set_sizes(
	logical_size_px: Vector2,
	display_base_size_px: Vector2
) -> void:
	_logical_size_px = Vector2(
		maxf(logical_size_px.x, 8.0),
		maxf(logical_size_px.y, 8.0)
	)

	if display_base_size_px == Vector2.ZERO:
		_display_base_size_px = _logical_size_px
	else:
		_display_base_size_px = Vector2(
			maxf(display_base_size_px.x, 8.0),
			maxf(display_base_size_px.y, 8.0)
		)

	_refresh_visual_size()
	_apply_layout()


func get_logical_size() -> Vector2:
	return _logical_size_px


func get_display_base_size() -> Vector2:
	return _display_base_size_px


func get_visual_size() -> Vector2:
	return _visual_size_px


func snap_to_global_center_position(
	global_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	_kill_tween(_position_tween)
	_kill_tween(_rotation_tween)

	global_position = global_center_position
	rotation = rotation_radians


func snap_to_overlay_position(
	overlay_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	_kill_tween(_position_tween)
	_kill_tween(_rotation_tween)

	position = overlay_center_position
	rotation = rotation_radians


func snap_position_to_overlay_center(
	overlay_center_position: Vector2
) -> void:
	_kill_tween(_position_tween)
	position = overlay_center_position


func snap_rotation_to(rotation_radians: float) -> void:
	_kill_tween(_rotation_tween)
	rotation = rotation_radians


func tween_rotation_to(rotation_radians: float) -> void:
	_kill_tween(_rotation_tween)

	_rotation_from = rotation
	_rotation_to = rotation_radians

	var duration_sec: float = _get_move_duration_sec()

	_rotation_tween = create_tween()
	_rotation_tween.set_trans(Tween.TRANS_CUBIC)
	_rotation_tween.set_ease(Tween.EASE_OUT)
	_rotation_tween.tween_method(
		_apply_rotation_tween_sample,
		0.0,
		1.0,
		duration_sec
	)


func tween_to_overlay_position(
	overlay_center_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	_kill_tween(_position_tween)
	_kill_tween(_rotation_tween)

	var duration_sec: float = _get_move_duration_sec()

	_position_tween = create_tween()
	_position_tween.set_trans(Tween.TRANS_CUBIC)
	_position_tween.set_ease(Tween.EASE_OUT)
	_position_tween.tween_property(
		self,
		"position",
		overlay_center_position,
		duration_sec
	)

	_rotation_from = rotation
	_rotation_to = rotation_radians

	_rotation_tween = create_tween()
	_rotation_tween.set_trans(Tween.TRANS_CUBIC)
	_rotation_tween.set_ease(Tween.EASE_OUT)
	_rotation_tween.tween_method(
		_apply_rotation_tween_sample,
		0.0,
		1.0,
		duration_sec
	)


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

	_play_sprite_shake(
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

	_play_sprite_shake(
		visual_definition.insert_shake_offset_px,
		visual_definition.insert_shake_secondary_offset_px,
		deg_to_rad(visual_definition.insert_shake_axis_deg),
		deg_to_rad(visual_definition.insert_shake_secondary_axis_deg),
		visual_definition.insert_shake_frequency_hz,
		visual_definition.insert_shake_secondary_frequency_hz,
		deg_to_rad(visual_definition.insert_shake_rotation_deg),
		visual_definition.insert_shake_duration_sec
	)


func play_rotate_feedback(direction: int) -> void:
	if not is_instance_valid(_sprite):
		return

	var signed_direction: float = sign(float(direction))
	if is_zero_approx(signed_direction):
		signed_direction = 1.0

	_kill_tween(_sprite_rotation_tween)
	_sprite.rotation = 0.0

	_sprite_rotation_tween = create_tween()
	_sprite_rotation_tween.set_trans(Tween.TRANS_CUBIC)
	_sprite_rotation_tween.set_ease(Tween.EASE_OUT)
	_sprite_rotation_tween.tween_property(
		_sprite,
		"rotation",
		deg_to_rad(5.0) * signed_direction,
		0.045
	)
	_sprite_rotation_tween.tween_property(
		_sprite,
		"rotation",
		0.0,
		0.065
	)

	_play_sprite_shake(
		2.5,
		0.8,
		0.0 if signed_direction > 0.0 else PI,
		PI * 0.5,
		18.0,
		28.0,
		deg_to_rad(1.5) * signed_direction,
		0.08
	)


func _apply_rotation_tween_sample(weight: float) -> void:
	rotation = lerp_angle(_rotation_from, _rotation_to, weight)


func _apply_definition_visuals() -> void:
	if not is_instance_valid(_sprite):
		return

	if _organ == null or _organ.definition == null:
		_sprite.sprite_frames = null
		_sprite.modulate = Color.WHITE
		_sprite.stop()
		return

	var definition: OrganDefinition = _organ.definition
	var organ_color: Color = definition.grid_tint

	if organ_color.a <= 0.01:
		organ_color.a = 1.0

	if definition.visual_definition != null:
		if definition.visual_definition.tint.a > 0.01:
			organ_color *= definition.visual_definition.tint

	_apply_sprite_source()
	_sprite.modulate = organ_color
	_refresh_visual_size()
	_apply_layout()


func _apply_sprite_source() -> void:
	if _organ == null or _organ.definition == null:
		_sprite.sprite_frames = null
		_sprite.stop()
		return

	var visual_definition: OrganVisualDefinition = (
		_organ.definition.visual_definition
	)

	if visual_definition == null:
		_sprite.sprite_frames = null
		_sprite.stop()
		return

	if visual_definition.sprite_frames != null:
		_sprite.sprite_frames = visual_definition.sprite_frames

		if visual_definition.sprite_frames.has_animation(DEFAULT_ANIMATION):
			_sprite.animation = DEFAULT_ANIMATION
		else:
			var animation_names: PackedStringArray = (
				visual_definition.sprite_frames.get_animation_names()
			)

			if animation_names.is_empty():
				_sprite.sprite_frames = null
				_sprite.stop()
				return

			_sprite.animation = StringName(animation_names[0])

		_sprite.frame = 0

		if visual_definition.autoplay:
			_sprite.play()
		else:
			_sprite.stop()

		return

	var icon: Texture2D = visual_definition.icon
	if icon == null:
		_sprite.sprite_frames = null
		_sprite.stop()
		return

	var frames: SpriteFrames = SpriteFrames.new()
	if not frames.has_animation(DEFAULT_ANIMATION):
		frames.add_animation(DEFAULT_ANIMATION)
	frames.add_frame(DEFAULT_ANIMATION, icon)

	_sprite.sprite_frames = frames
	_sprite.animation = DEFAULT_ANIMATION
	_sprite.frame = 0
	_sprite.stop()


func _refresh_visual_size() -> void:
	var scale_value: float = global_icon_scale

	if _organ != null and _organ.definition != null:
		scale_value *= _organ.definition.get_visual_scale()

	_visual_size_px = _display_base_size_px * scale_value


func _apply_layout() -> void:
	if not is_instance_valid(_pivot) or not is_instance_valid(_sprite):
		return

	_pivot.position = Vector2.ZERO
	_pivot.rotation = 0.0

	var texture_size: Vector2 = _get_source_texture_size()

	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		_sprite.scale = Vector2.ONE
		_sprite.position = Vector2.ZERO
		_sprite.centered = true
		_sprite.rotation = 0.0
		_sprite_rest_position = Vector2.ZERO
		_sprite_rest_rotation = 0.0
		return

	var uniform_scale_x: float = _visual_size_px.x / texture_size.x
	var uniform_scale_y: float = _visual_size_px.y / texture_size.y
	var uniform_scale: float = minf(uniform_scale_x, uniform_scale_y)

	_sprite.scale = Vector2.ONE * uniform_scale
	_sprite.position = Vector2.ZERO
	_sprite.centered = true
	_sprite.rotation = 0.0

	_sprite_rest_position = Vector2.ZERO
	_sprite_rest_rotation = 0.0


func _get_source_texture_size() -> Vector2:
	if not is_instance_valid(_sprite):
		return Vector2.ONE

	if _sprite.sprite_frames == null:
		return Vector2.ONE

	if not _sprite.sprite_frames.has_animation(_sprite.animation):
		return Vector2.ONE

	var frame_count: int = _sprite.sprite_frames.get_frame_count(_sprite.animation)
	if frame_count <= 0:
		return Vector2.ONE

	var frame_index: int = clampi(_sprite.frame, 0, frame_count - 1)
	var current_texture: Texture2D = _sprite.sprite_frames.get_frame_texture(
		_sprite.animation,
		frame_index
	)

	if current_texture == null:
		return Vector2.ONE

	return current_texture.get_size()


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
	_scale_tween.tween_property(
		_pivot,
		"scale",
		target_scale,
		duration_sec
	)


func _play_sprite_shake(
	primary_offset_px: float,
	secondary_offset_px: float,
	primary_axis_radians: float,
	secondary_axis_radians: float,
	frequency_hz: float,
	secondary_frequency_hz: float,
	rotation_radians: float,
	duration_sec: float
) -> void:
	if not is_instance_valid(_sprite):
		return

	_kill_tween(_shake_tween)

	_sprite.position = _sprite_rest_position
	_sprite.rotation = _sprite_rest_rotation

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

	_shake_tween = create_tween().bind_node(self)
	_shake_tween.tween_method(
		_apply_shake_sample,
		0.0,
		1.0,
		duration_sec
	)
	_shake_tween.finished.connect(_reset_sprite_shake_state, CONNECT_ONE_SHOT)


func _apply_shake_sample(progress: float) -> void:
	if not is_instance_valid(_sprite):
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

	_sprite.position = _sprite_rest_position + offset
	_sprite.rotation = _sprite_rest_rotation + (
		_shake_rotation_radians * primary_wave * envelope
	)


func _reset_sprite_shake_state() -> void:
	if not is_instance_valid(_sprite):
		return

	_sprite.position = _sprite_rest_position
	_sprite.rotation = _sprite_rest_rotation


func _get_move_duration_sec() -> float:
	if _organ == null or _organ.definition == null:
		return 0.12

	var visual_definition: OrganVisualDefinition = (
		_organ.definition.visual_definition
	)

	if visual_definition == null:
		return 0.12

	return visual_definition.move_duration_sec


func stop_all_motion() -> void:
	_kill_tween(_position_tween)
	_kill_tween(_rotation_tween)
	_kill_tween(_scale_tween)
	_kill_tween(_shake_tween)
	_kill_tween(_sprite_rotation_tween)

	_pivot.scale = Vector2.ONE
	_reset_sprite_shake_state()


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
