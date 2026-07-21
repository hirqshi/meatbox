class_name CrosshairLayer
extends Control

var _texture: Texture2D
var _split_mode: CrosshairPresentationDefinition.SplitMode = (
	CrosshairPresentationDefinition.SplitMode.NONE
)

var _plus_arm_thickness_px: float = 1.0
var _plus_center_gap_px: float = 0.0

var _separation_px: float = 0.0
var _visual_scale: float = 1.0
var _tint: Color = Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	resized.connect(_on_resized)
	_update_pivot_offset()


func set_presentation(
	texture: Texture2D,
	split_mode: CrosshairPresentationDefinition.SplitMode,
	plus_arm_thickness_px: int,
	plus_center_gap_px: int,
	visual_scale: float,
	tint: Color
) -> void:
	_texture = texture
	_split_mode = split_mode
	_plus_arm_thickness_px = maxf(
		float(plus_arm_thickness_px),
		1.0
	)
	_plus_center_gap_px = maxf(
		float(plus_center_gap_px),
		0.0
	)
	_visual_scale = maxf(visual_scale, 0.01)
	_tint = tint

	queue_redraw()


func set_separation_px(value: float) -> void:
	var next_separation_px: float = value

	if _split_mode == (
		CrosshairPresentationDefinition.SplitMode.NONE
	):
		next_separation_px = 0.0

	if is_equal_approx(
		_separation_px,
		next_separation_px
	):
		return

	_separation_px = next_separation_px
	queue_redraw()


func _draw() -> void:
	if _texture == null:
		return

	var texture_size: Vector2 = _texture.get_size()

	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	match _split_mode:
		CrosshairPresentationDefinition.SplitMode.NONE:
			_draw_whole(texture_size)

		CrosshairPresentationDefinition.SplitMode.PLUS_FOUR_ARMS:
			_draw_plus_four_arms(texture_size)

		CrosshairPresentationDefinition.SplitMode.VERTICAL_HALVES:
			_draw_vertical_halves(texture_size)

		CrosshairPresentationDefinition.SplitMode.HORIZONTAL_HALVES:
			_draw_horizontal_halves(texture_size)

		CrosshairPresentationDefinition.SplitMode.THREE_VERTICAL:
			_draw_three_vertical(texture_size)

		CrosshairPresentationDefinition.SplitMode.FOUR_CORNERS:
			_draw_four_corners(texture_size)


func _draw_whole(texture_size: Vector2) -> void:
	var target_size: Vector2 = texture_size * _visual_scale
	var target_rect: Rect2 = Rect2(
		size * 0.5 - target_size * 0.5,
		target_size
	)

	draw_texture_rect_region(
		_texture,
		target_rect,
		Rect2(Vector2.ZERO, texture_size),
		_tint
	)


func _draw_plus_four_arms(texture_size: Vector2) -> void:
	var texture_center: Vector2 = texture_size * 0.5

	var arm_thickness: float = minf(
		_plus_arm_thickness_px,
		minf(texture_size.x, texture_size.y)
	)

	var half_arm_thickness: float = arm_thickness * 0.5

	var center_gap_px: float = minf(
		_plus_center_gap_px,
		minf(texture_size.x, texture_size.y)
	)

	var half_gap: float = center_gap_px * 0.5

	var top_height: float = texture_center.y - half_gap
	var right_width: float = (
		texture_size.x
		- texture_center.x
		- half_gap
	)
	var bottom_height: float = (
		texture_size.y
		- texture_center.y
		- half_gap
	)
	var left_width: float = texture_center.x - half_gap

	if (
		top_height <= 0.0
		or right_width <= 0.0
		or bottom_height <= 0.0
		or left_width <= 0.0
	):
		return

	var top_region: Rect2 = Rect2(
		texture_center.x - half_arm_thickness,
		0.0,
		arm_thickness,
		top_height
	)

	var right_region: Rect2 = Rect2(
		texture_center.x + half_gap,
		texture_center.y - half_arm_thickness,
		right_width,
		arm_thickness
	)

	var bottom_region: Rect2 = Rect2(
		texture_center.x - half_arm_thickness,
		texture_center.y + half_gap,
		arm_thickness,
		bottom_height
	)

	var left_region: Rect2 = Rect2(
		0.0,
		texture_center.y - half_arm_thickness,
		left_width,
		arm_thickness
	)

	_draw_part(
		top_region,
		Vector2(0.0, -_separation_px),
		texture_size
	)
	_draw_part(
		right_region,
		Vector2(_separation_px, 0.0),
		texture_size
	)
	_draw_part(
		bottom_region,
		Vector2(0.0, _separation_px),
		texture_size
	)
	_draw_part(
		left_region,
		Vector2(-_separation_px, 0.0),
		texture_size
	)


func _draw_vertical_halves(texture_size: Vector2) -> void:
	var half_width: float = texture_size.x * 0.5

	_draw_part(
		Rect2(
			0.0,
			0.0,
			half_width,
			texture_size.y
		),
		Vector2(-_separation_px, 0.0),
		texture_size
	)

	_draw_part(
		Rect2(
			half_width,
			0.0,
			half_width,
			texture_size.y
		),
		Vector2(_separation_px, 0.0),
		texture_size
	)


func _draw_horizontal_halves(texture_size: Vector2) -> void:
	var half_height: float = texture_size.y * 0.5

	_draw_part(
		Rect2(
			0.0,
			0.0,
			texture_size.x,
			half_height
		),
		Vector2(0.0, -_separation_px),
		texture_size
	)

	_draw_part(
		Rect2(
			0.0,
			half_height,
			texture_size.x,
			half_height
		),
		Vector2(0.0, _separation_px),
		texture_size
	)


func _draw_three_vertical(texture_size: Vector2) -> void:
	var third_width: float = texture_size.x / 3.0

	_draw_part(
		Rect2(
			0.0,
			0.0,
			third_width,
			texture_size.y
		),
		Vector2(-_separation_px, 0.0),
		texture_size
	)

	_draw_part(
		Rect2(
			third_width,
			0.0,
			third_width,
			texture_size.y
		),
		Vector2.ZERO,
		texture_size
	)

	_draw_part(
		Rect2(
			third_width * 2.0,
			0.0,
			third_width,
			texture_size.y
		),
		Vector2(_separation_px, 0.0),
		texture_size
	)


func _draw_four_corners(texture_size: Vector2) -> void:
	var half_width: float = texture_size.x * 0.5
	var half_height: float = texture_size.y * 0.5

	_draw_part(
		Rect2(
			0.0,
			0.0,
			half_width,
			half_height
		),
		Vector2(-_separation_px, -_separation_px),
		texture_size
	)

	_draw_part(
		Rect2(
			half_width,
			0.0,
			half_width,
			half_height
		),
		Vector2(_separation_px, -_separation_px),
		texture_size
	)

	_draw_part(
		Rect2(
			0.0,
			half_height,
			half_width,
			half_height
		),
		Vector2(-_separation_px, _separation_px),
		texture_size
	)

	_draw_part(
		Rect2(
			half_width,
			half_height,
			half_width,
			half_height
		),
		Vector2(_separation_px, _separation_px),
		texture_size
	)


func _draw_part(
	source_rect: Rect2,
	separation_offset: Vector2,
	texture_size: Vector2
) -> void:
	if source_rect.size.x <= 0.0:
		return

	if source_rect.size.y <= 0.0:
		return

	var target_size: Vector2 = (
		source_rect.size
		* _visual_scale
	)

	var source_relative_center: Vector2 = (
		source_rect.get_center()
		- texture_size * 0.5
	) * _visual_scale

	var target_center: Vector2 = (
		size * 0.5
		+ source_relative_center
		+ separation_offset
	)

	var target_rect: Rect2 = Rect2(
		target_center - target_size * 0.5,
		target_size
	)

	draw_texture_rect_region(
		_texture,
		target_rect,
		source_rect,
		_tint
	)


func _on_resized() -> void:
	_update_pivot_offset()


func _update_pivot_offset() -> void:
	pivot_offset = size * 0.5
