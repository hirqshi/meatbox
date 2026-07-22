class_name OrganGridView
extends Control

signal organ_drag_requested(organ: OrganInstance)

@export_category("Grid")
@export_range(1, 20, 1)
var columns: int = 4:
	set(value):
		columns = maxi(value, 1)
		_rebuild_grid()

@export_range(1, 20, 1)
var rows: int = 5:
	set(value):
		rows = maxi(value, 1)
		_rebuild_grid()

@export_range(0.0, 64.0, 1.0, "suffix:px")
var cell_gap_px: float = 4.0:
	set(value):
		cell_gap_px = maxf(value, 0.0)
		_queue_layout()

@export_category("Scenes")
@export var organ_view_scene: PackedScene

@export_category("Dependencies")
@export var organ_visual_manager: OrganVisualManager

@onready var _organ_views: Control = $OrganViews

var _model: OrganGridModel
var _views_by_organ: Dictionary[OrganInstance, OrganView] = {}

var _drop_preview_cells: Array[Vector2i] = []
var _is_drop_preview_valid: bool = false


func _ready() -> void:
	assert(
		organ_view_scene != null,
		"OrganGridView requires organ_view_scene."
	)
	assert(_organ_views != null, "OrganGridView requires OrganViews.")

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_organ_views.mouse_filter = Control.MOUSE_FILTER_IGNORE

	resized.connect(_queue_layout)
	_rebuild_grid()


func setup(model: OrganGridModel) -> void:
	assert(model != null, "OrganGridView requires OrganGridModel.")

	_disconnect_model()
	_model = model
	_connect_model()

	_sync_views()
	_queue_layout()
	queue_redraw()


func get_model() -> OrganGridModel:
	return _model


func has_organ(organ: OrganInstance) -> bool:
	return _views_by_organ.has(organ)


func set_organ_visible(
	organ: OrganInstance,
	is_visible: bool
) -> void:
	var organ_view: OrganView = _views_by_organ.get(organ)

	if is_instance_valid(organ_view):
		organ_view.visible = is_visible


func get_cell_side_px() -> float:
	if columns <= 0 or rows <= 0:
		return 0.0

	var total_gap_x: float = cell_gap_px * float(maxi(columns - 1, 0))
	var total_gap_y: float = cell_gap_px * float(maxi(rows - 1, 0))

	var available_width: float = maxf(size.x - total_gap_x, 0.0)
	var available_height: float = maxf(size.y - total_gap_y, 0.0)

	var cell_width: float = available_width / float(columns)
	var cell_height: float = available_height / float(rows)

	return floorf(minf(cell_width, cell_height))


func get_cell_size() -> Vector2:
	var side: float = get_cell_side_px()
	return Vector2(side, side)


func get_grid_pixel_size() -> Vector2:
	var side: float = get_cell_side_px()

	if side <= 0.0:
		return Vector2.ZERO

	return Vector2(
		float(columns) * side + float(maxi(columns - 1, 0)) * cell_gap_px,
		float(rows) * side + float(maxi(rows - 1, 0)) * cell_gap_px
	)


func get_grid_origin_local() -> Vector2:
	return (size - get_grid_pixel_size()) * 0.5


func get_grid_rect_local() -> Rect2:
	return Rect2(get_grid_origin_local(), get_grid_pixel_size())


func get_cell_rect(cell: Vector2i) -> Rect2:
	var side: float = get_cell_side_px()
	var step: float = side + cell_gap_px
	var origin: Vector2 = get_grid_origin_local()

	return Rect2(
		origin + Vector2(float(cell.x) * step, float(cell.y) * step),
		Vector2(side, side)
	)


func get_organ_rect(organ: OrganInstance) -> Rect2:
	if _model == null or organ == null or organ.definition == null:
		return Rect2()

	var grid_position: Vector2i = _model.get_position(organ)

	if grid_position == Vector2i(-1, -1):
		return Rect2()

	var first_cell_rect: Rect2 = get_cell_rect(grid_position)
	var side: float = get_cell_side_px()

	var organ_width: float = (
		side * float(organ.definition.grid_width_cells)
		+ cell_gap_px * float(organ.definition.grid_width_cells - 1)
	)

	var organ_height: float = (
		side * float(organ.definition.grid_height_cells)
		+ cell_gap_px * float(organ.definition.grid_height_cells - 1)
	)

	return Rect2(
		first_cell_rect.position,
		Vector2(organ_width, organ_height)
	)


func get_organ_viewport_center(organ: OrganInstance) -> Vector2:
	var organ_rect: Rect2 = get_organ_rect(organ)
	var local_center: Vector2 = organ_rect.position + organ_rect.size * 0.5
	return get_global_transform_with_canvas() * local_center


func get_organ_canvas_center(organ: OrganInstance) -> Vector2:
	var organ_rect: Rect2 = get_organ_rect(organ)
	var local_center: Vector2 = organ_rect.position + organ_rect.size * 0.5
	return get_global_transform_with_canvas() * local_center


func get_drop_grid_position_from_viewport_point(
	viewport_position: Vector2,
	organ: OrganInstance
) -> Vector2i:
	var local_point: Vector2 = viewport_to_local_position(viewport_position)
	return get_drop_grid_position_from_local_point(local_point, organ)


func get_drop_grid_position_from_local_point(
	local_point: Vector2,
	organ: OrganInstance
) -> Vector2i:
	if organ == null or organ.definition == null:
		return Vector2i(-1, -1)

	var grid_rect: Rect2 = get_grid_rect_local()
	if not grid_rect.has_point(local_point):
		return Vector2i(-1, -1)

	var side: float = get_cell_side_px()
	var step: float = side + cell_gap_px
	if step <= 0.0:
		return Vector2i(-1, -1)

	var relative: Vector2 = local_point - grid_rect.position

	var hovered_cell: Vector2i = Vector2i(
		floori(relative.x / step),
		floori(relative.y / step)
	)

	var cell_local_x: float = fposmod(relative.x, step)
	var cell_local_y: float = fposmod(relative.y, step)

	if cell_local_x > side or cell_local_y > side:
		return Vector2i(-1, -1)

	var offset_cells: Vector2i = Vector2i(
		organ.definition.grid_width_cells / 2,
		organ.definition.grid_height_cells / 2
	)

	return hovered_cell - offset_cells


func is_viewport_point_over_grid(
	viewport_position: Vector2
) -> bool:
	var local_point: Vector2 = viewport_to_local_position(viewport_position)
	return get_grid_rect_local().has_point(local_point)


func update_drop_preview_for_viewport_position(
	organ: OrganInstance,
	viewport_position: Vector2
) -> void:
	if _model == null or organ == null:
		clear_drop_preview()
		return

	var target_position: Vector2i = (
		get_drop_grid_position_from_viewport_point(
			viewport_position,
			organ
		)
	)

	_drop_preview_cells = _model.get_occupied_cells(
		organ,
		target_position
	)
	_is_drop_preview_valid = _model.can_place(
		organ,
		target_position
	)

	queue_redraw()


func clear_drop_preview() -> void:
	if _drop_preview_cells.is_empty() and not _is_drop_preview_valid:
		return

	_drop_preview_cells.clear()
	_is_drop_preview_valid = false
	queue_redraw()


func can_place_organ_at_viewport_position(
	organ: OrganInstance,
	viewport_position: Vector2
) -> bool:
	if _model == null or organ == null:
		return false

	var target_position: Vector2i = (
		get_drop_grid_position_from_viewport_point(
			viewport_position,
			organ
		)
	)

	return _model.can_place(organ, target_position)


func viewport_to_local_position(
	viewport_position: Vector2
) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func _draw() -> void:
	for y: int in rows:
		for x: int in columns:
			var cell_rect: Rect2 = get_cell_rect(Vector2i(x, y))

			draw_rect(
				cell_rect,
				Color(0.13, 0.05, 0.05, 0.9),
				true
			)
			draw_rect(
				cell_rect,
				Color(0.65, 0.2, 0.2, 0.9),
				false,
				1.0
			)

	if _model == null:
		return

	for cell: Vector2i in _drop_preview_cells:
		if not _model.is_cell_inside(cell):
			continue

		var preview_color: Color = Color(0.15, 0.9, 0.25, 0.42)

		if not _is_drop_preview_valid:
			preview_color = Color(0.95, 0.15, 0.15, 0.48)

		draw_rect(
			get_cell_rect(cell),
			preview_color,
			true
		)


func _rebuild_grid() -> void:
	if not is_node_ready():
		return

	if _model == null:
		_model = OrganGridModel.new(columns, rows)
		_connect_model()
	else:
		_model.resize(columns, rows)

	queue_redraw()
	_sync_views()


func _queue_layout() -> void:
	queue_redraw()
	_layout_organ_views()


func _sync_views() -> void:
	if _model == null or not is_node_ready():
		return

	var installed_organs: Array[OrganInstance] = (
		_model.get_installed_organs()
	)

	var existing_organs: Array[OrganInstance] = []
	existing_organs.assign(_views_by_organ.keys())

	for organ: OrganInstance in existing_organs:
		if installed_organs.has(organ):
			continue

		var removed_view: OrganView = _views_by_organ.get(organ)
		if is_instance_valid(removed_view):
			removed_view.queue_free()

		_views_by_organ.erase(organ)

	for organ: OrganInstance in installed_organs:
		if _views_by_organ.has(organ):
			continue

		var organ_view: OrganView = (
			organ_view_scene.instantiate() as OrganView
		)

		if organ_view == null:
			push_error(
				"organ_view_scene must instantiate OrganView."
			)
			continue

		_organ_views.add_child(organ_view)
		organ_view.setup(organ, self)
		organ_view.organ_drag_requested.connect(
			_on_organ_view_drag_requested
		)
		organ_view.organ_hover_started.connect(
			_on_organ_view_hover_started
		)
		organ_view.organ_hover_ended.connect(
			_on_organ_view_hover_ended
		)
		organ_view.organ_clicked.connect(
			_on_organ_view_clicked
		)

		_views_by_organ[organ] = organ_view

	_layout_organ_views()


func _layout_organ_views() -> void:
	if _model == null:
		return

	for organ: OrganInstance in _views_by_organ:
		var organ_view: OrganView = _views_by_organ.get(organ)

		if not is_instance_valid(organ_view):
			continue

		var organ_rect: Rect2 = get_organ_rect(organ)

		organ_view.position = organ_rect.position
		organ_view.size = organ_rect.size
		organ_view.pivot_offset = organ_rect.size * 0.5


func _connect_model() -> void:
	if _model == null:
		return

	if not _model.changed.is_connected(_on_model_changed):
		_model.changed.connect(_on_model_changed)


func _disconnect_model() -> void:
	if _model == null:
		return

	if _model.changed.is_connected(_on_model_changed):
		_model.changed.disconnect(_on_model_changed)


func _on_model_changed() -> void:
	_sync_views()
	_queue_layout()
	queue_redraw()


func _on_organ_view_drag_requested(organ: OrganInstance) -> void:
	organ_drag_requested.emit(organ)


func _on_organ_view_hover_started(organ: OrganInstance) -> void:
	if organ_visual_manager == null:
		return

	organ_visual_manager.play_hover_enter_for(organ)


func _on_organ_view_hover_ended(organ: OrganInstance) -> void:
	if organ_visual_manager == null:
		return

	organ_visual_manager.play_hover_exit_for(organ)


func _on_organ_view_clicked(organ: OrganInstance) -> void:
	if organ_visual_manager == null:
		return

	organ_visual_manager.play_click_feedback_for(organ)
