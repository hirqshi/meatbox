class_name OrganGridView
extends Control

signal organ_world_drop_requested(
	organ: OrganInstance,
	screen_position: Vector2
)

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

@onready var _organ_views: Control = $OrganViews

var _model: OrganGridModel
var _views_by_organ: Dictionary[OrganInstance, OrganView] = {}
var _drop_preview_cells: Array[Vector2i] = []
var _is_drop_preview_valid: bool = false
var _inventory: OrganInventoryComponent


func _ready() -> void:
	assert(
		organ_view_scene != null,
		"OrganGridView requires organ_view_scene."
	)

	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10

	_organ_views.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_organ_views.z_index = 10
	_organ_views.show_behind_parent = false

	resized.connect(_queue_layout)

	_rebuild_grid()


func setup(
	model: OrganGridModel,
	inventory: OrganInventoryComponent
) -> void:
	assert(model != null, "OrganGridView requires OrganGridModel.")
	assert(
		inventory != null,
		"OrganGridView requires OrganInventoryComponent."
	)

	_disconnect_model()

	_model = model
	_inventory = inventory

	_connect_model()
	_sync_views()
	_queue_layout()
	queue_redraw()


func get_model() -> OrganGridModel:
	return _model


func get_cell_size() -> Vector2:
	var total_gap_x: float = (
		cell_gap_px * float(columns - 1)
	)
	var total_gap_y: float = (
		cell_gap_px * float(rows - 1)
	)

	var available_width: float = maxf(
		size.x - total_gap_x,
		0.0
	)
	var available_height: float = maxf(
		size.y - total_gap_y,
		0.0
	)

	return Vector2(
		available_width / float(columns),
		available_height / float(rows)
	)


func get_cell_rect(cell: Vector2i) -> Rect2:
	var cell_size: Vector2 = get_cell_size()

	return Rect2(
		Vector2(
			float(cell.x) * (
				cell_size.x + cell_gap_px
			),
			float(cell.y) * (
				cell_size.y + cell_gap_px
			)
		),
		cell_size
	)


func get_organ_rect(
	organ: OrganInstance
) -> Rect2:
	if _model == null or organ == null:
		return Rect2()

	var grid_position: Vector2i = (
		_model.get_position(organ)
	)

	if grid_position == Vector2i(-1, -1):
		return Rect2()

	var cell_rect: Rect2 = get_cell_rect(grid_position)

	var organ_width: float = (
		cell_rect.size.x
		* float(organ.definition.grid_width_cells)
		+ cell_gap_px
		* float(
			organ.definition.grid_width_cells - 1
		)
	)

	var organ_height: float = (
		cell_rect.size.y
		* float(organ.definition.grid_height_cells)
		+ cell_gap_px
		* float(
			organ.definition.grid_height_cells - 1
		)
	)

	return Rect2(
		cell_rect.position,
		Vector2(organ_width, organ_height)
	)


func _can_drop_data(
	at_position: Vector2,
	data: Variant
) -> bool:
	var drag_data: OrganDragData = data as OrganDragData

	if drag_data == null or drag_data.organ == null:
		return false

	var target_position: Vector2i = (
		_get_drop_grid_position(
			at_position,
			drag_data.grab_offset_cells
		)
	)

	return _model.can_place(
		drag_data.organ,
		target_position
	)


func _drop_data(
	at_position: Vector2,
	data: Variant
) -> void:
	var drag_data: OrganDragData = data as OrganDragData

	if drag_data == null or drag_data.organ == null:
		clear_drop_preview()
		return

	var target_position: Vector2i = (
		_get_drop_grid_position(
			at_position,
			drag_data.grab_offset_cells
		)
	)

	var was_placed: bool = false

	if drag_data.source_type == OrganDragData.SourceType.PILE:
		if _inventory != null:
			was_placed = _inventory.try_install_loose_organ(
				drag_data.organ,
				target_position
			)
	else:
		was_placed = _model.try_place(
			drag_data.organ,
			target_position
		)

	if was_placed and is_instance_valid(
		drag_data.source_view
	):
		drag_data.source_view.show()

	clear_drop_preview()


func _draw() -> void:
	for y: int in rows:
		for x: int in columns:
			var cell_rect: Rect2 = get_cell_rect(
				Vector2i(x, y)
			)

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
	for cell: Vector2i in _drop_preview_cells:
		if not _model.is_cell_inside(cell):
			continue

		var preview_color: Color = Color(
			0.15,
			0.9,
			0.25,
			0.42
		)

		if not _is_drop_preview_valid:
			preview_color = Color(
				0.95,
				0.15,
				0.15,
				0.48
			)

		draw_rect(
			get_cell_rect(cell),
			preview_color,
			true
		)


func _gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseMotion:
		return

	var drag_data: OrganDragData = (
		get_viewport().gui_get_drag_data()
		as OrganDragData
	)

	if drag_data == null or drag_data.organ == null:
		clear_drop_preview()
		return

	var target_position: Vector2i = (
		_get_drop_grid_position(
			event.position,
			drag_data.grab_offset_cells
		)
	)

	_drop_preview_cells = _model.get_occupied_cells(
		drag_data.organ,
		target_position
	)
	_is_drop_preview_valid = _model.can_place(
		drag_data.organ,
		target_position
	)

	queue_redraw()


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

		var organ_view: OrganView = (
			_views_by_organ.get(organ)
		)

		if is_instance_valid(organ_view):
			organ_view.queue_free()

		_views_by_organ.erase(organ)

	for organ: OrganInstance in installed_organs:
		if _views_by_organ.has(organ):
			continue

		var organ_view: OrganView = (
			organ_view_scene.instantiate()
			as OrganView
		)

		if organ_view == null:
			push_error(
				"organ_view_scene must instantiate OrganView."
			)
			continue

		_organ_views.add_child(organ_view)
		organ_view.setup(organ, self)
		organ_view.world_drop_requested.connect(
			_on_organ_view_world_drop_requested
		)
		_views_by_organ[organ] = organ_view

	_layout_organ_views()
	
	print(
		"Grid sync: model=%d, views=%d"
		% [
			installed_organs.size(),
			_views_by_organ.size()
		]
	)
	

func _layout_organ_views() -> void:
	if _model == null:
		return

	for organ: OrganInstance in _views_by_organ:
		var organ_view: OrganView = (
			_views_by_organ.get(organ)
		)

		if not is_instance_valid(organ_view):
			continue

		var organ_rect: Rect2 = get_organ_rect(organ)

		organ_view.position = organ_rect.position
		organ_view.size = organ_rect.size
		organ_view.pivot_offset = (
			organ_rect.size * 0.5
		)
		print(
			"OrganView '%s': position=%s size=%s texture=%s visible=%s"
			% [
				organ.definition.display_name,
				organ_view.position,
				organ_view.size,
				organ_view.texture,
				organ_view.is_visible_in_tree()
			]
		)


func clear_drop_preview() -> void:
	if _drop_preview_cells.is_empty():
		return

	_drop_preview_cells.clear()
	_is_drop_preview_valid = false
	queue_redraw()


func _get_drop_grid_position(
	at_position: Vector2,
	grab_offset_cells: Vector2i
) -> Vector2i:
	var cell_size: Vector2 = get_cell_size()
	var cell_stride: Vector2 = cell_size + Vector2(
		cell_gap_px,
		cell_gap_px
	)

	if cell_stride.x <= 0.0 or cell_stride.y <= 0.0:
		return Vector2i(-1, -1)

	var hovered_cell: Vector2i = Vector2i(
		floori(at_position.x / cell_stride.x),
		floori(at_position.y / cell_stride.y)
	)

	return hovered_cell - grab_offset_cells


func _connect_model() -> void:
	if _model == null:
		return

	if not _model.changed.is_connected(
		_on_model_changed
	):
		_model.changed.connect(_on_model_changed)


func _disconnect_model() -> void:
	if _model == null:
		return

	if _model.changed.is_connected(
		_on_model_changed
	):
		_model.changed.disconnect(_on_model_changed)
	

func _on_model_changed() -> void:
	_sync_views()
	_queue_layout()
	queue_redraw()


func _on_organ_view_world_drop_requested(
	organ: OrganInstance,
	screen_position: Vector2
) -> void:
	organ_world_drop_requested.emit(
		organ,
		screen_position
	)
