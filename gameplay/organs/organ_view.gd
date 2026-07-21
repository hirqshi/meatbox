class_name OrganView
extends TextureRect

signal world_drop_requested(
	organ: OrganInstance,
	screen_position: Vector2
)

var _organ: OrganInstance
var _grid_view: OrganGridView
var _is_dragging: bool = false


func setup(
	organ: OrganInstance,
	grid_view: OrganGridView
) -> void:
	assert(
		organ != null,
		"OrganView requires an OrganInstance."
	)
	assert(
		grid_view != null,
		"OrganView requires an OrganGridView."
	)
	assert(
		organ.definition != null,
		"OrganView requires an OrganDefinition."
	)

	_organ = organ
	_grid_view = grid_view

	texture = _organ.definition.icon
	modulate = _organ.definition.grid_tint

	mouse_filter = Control.MOUSE_FILTER_STOP
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _get_drag_data(
	at_position: Vector2
) -> Variant:
	if _organ == null or _grid_view == null:
		return null

	if _organ.definition == null:
		return null

	var cell_size: Vector2 = _grid_view.get_cell_size()
	var cell_stride: Vector2 = cell_size + Vector2(
		_grid_view.cell_gap_px,
		_grid_view.cell_gap_px
	)

	if cell_stride.x <= 0.0 or cell_stride.y <= 0.0:
		return null

	var grab_offset_cells: Vector2i = Vector2i(
		floori(at_position.x / cell_stride.x),
		floori(at_position.y / cell_stride.y)
	)

	grab_offset_cells.x = clampi(
		grab_offset_cells.x,
		0,
		_organ.definition.grid_width_cells - 1
	)
	grab_offset_cells.y = clampi(
		grab_offset_cells.y,
		0,
		_organ.definition.grid_height_cells - 1
	)

	var preview_root: Control = Control.new()
	preview_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var preview: TextureRect = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	preview.size = size
	preview.position = -at_position
	preview.modulate = modulate
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	preview_root.add_child(preview)
	set_drag_preview(preview_root)

	_is_dragging = true
	hide()

	return OrganDragData.new(
		_organ,
		OrganDragData.SourceType.GRID,
		grab_offset_cells,
		self
	)


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return

	if not _is_dragging:
		return

	_is_dragging = false

	var was_drag_successful: bool = (
		get_viewport().gui_is_drag_successful()
	)

	if was_drag_successful:
		return

	show()

	if _organ != null:
		world_drop_requested.emit(
			_organ,
			get_viewport().get_mouse_position()
		)
