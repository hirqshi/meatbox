class_name OrganVisualManager
extends Node

@export_category("Scenes")
@export var organ_visual_scene: PackedScene
@export var drag_overlay: Control

var _inventory: OrganInventoryComponent
var _grid_view: OrganGridView
var _pile: OrganPile

var _visuals_by_organ: Dictionary[OrganInstance, OrganVisual] = {}
var _dragged_organ: OrganInstance
var _drag_proxy_visual: OrganVisual


func setup(
	inventory: OrganInventoryComponent,
	grid_view: OrganGridView,
	pile: OrganPile
) -> void:
	assert(inventory != null, "OrganVisualManager requires inventory.")
	assert(grid_view != null, "OrganVisualManager requires grid_view.")
	assert(pile != null, "OrganVisualManager requires pile.")
	assert(
		organ_visual_scene != null,
		"OrganVisualManager requires organ_visual_scene."
	)
	assert(drag_overlay != null, "OrganVisualManager requires drag_overlay.")

	_inventory = inventory
	_grid_view = grid_view
	_pile = pile

	drag_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not _inventory.organ_grid_changed.is_connected(_on_state_changed):
		_inventory.organ_grid_changed.connect(_on_state_changed)
	if not _inventory.loose_organ_added.is_connected(_on_state_changed):
		_inventory.loose_organ_added.connect(_on_state_changed)
	if not _inventory.loose_organ_removed.is_connected(_on_state_changed):
		_inventory.loose_organ_removed.connect(_on_state_changed)

	_refresh_visuals()
	_sync_visual_targets(true)
	set_process(true)


func set_dragged_organ(organ: OrganInstance) -> void:
	_dragged_organ = organ

	if is_instance_valid(_drag_proxy_visual):
		_drag_proxy_visual.queue_free()

	_drag_proxy_visual = null

	if organ == null:
		return

	_drag_proxy_visual = organ_visual_scene.instantiate() as OrganVisual
	if _drag_proxy_visual == null:
		push_error("organ_visual_scene must instantiate OrganVisual.")
		return

	drag_overlay.add_child(_drag_proxy_visual)
	_drag_proxy_visual.setup(organ, _get_organ_size_px(organ))
	_drag_proxy_visual.visible = true
	_drag_proxy_visual.z_index = 100
	_drag_proxy_visual.top_level = false
	_drag_proxy_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var base_visual: OrganVisual = _visuals_by_organ.get(organ)
	if is_instance_valid(base_visual):
		base_visual.visible = false


func clear_dragged_organ() -> void:
	var dragged_organ: OrganInstance = _dragged_organ

	_dragged_organ = null

	if is_instance_valid(_drag_proxy_visual):
		_drag_proxy_visual.queue_free()

	_drag_proxy_visual = null

	var base_visual: OrganVisual = _visuals_by_organ.get(dragged_organ)
	if is_instance_valid(base_visual):
		base_visual.visible = true


func update_drag_proxy(
	viewport_position: Vector2,
	rotation_radians: float = 0.0
) -> void:
	if not is_instance_valid(_drag_proxy_visual):
		return

	_drag_proxy_visual.visible = true
	_drag_proxy_visual.set_visual_size(_get_organ_size_px(_dragged_organ))
	_drag_proxy_visual.snap_to_overlay_position(
		viewport_to_overlay_local(viewport_position),
		rotation_radians
	)


func sync_visual_targets(force_snap: bool = false) -> void:
	_sync_visual_targets(force_snap)


func _process(_delta: float) -> void:
	if _dragged_organ != null:
		return

	_sync_visual_targets(false)


func _refresh_visuals() -> void:
	if _inventory == null:
		return

	var all_organs: Array[OrganInstance] = []
	all_organs.append_array(_inventory.get_grid().get_installed_organs())
	all_organs.append_array(_inventory.get_loose_organs())

	for organ: OrganInstance in all_organs:
		_ensure_visual(organ)

	var existing_organs: Array[OrganInstance] = []
	existing_organs.assign(_visuals_by_organ.keys())

	for organ: OrganInstance in existing_organs:
		var still_exists: bool = (
			_inventory.is_organ_installed(organ)
			or _inventory.has_loose_organ(organ)
		)

		if still_exists:
			continue

		var visual: OrganVisual = _visuals_by_organ.get(organ)
		if is_instance_valid(visual):
			visual.queue_free()

		_visuals_by_organ.erase(organ)

	_sync_visual_targets(true)


func _ensure_visual(organ: OrganInstance) -> void:
	if organ == null:
		return

	if _visuals_by_organ.has(organ):
		var existing_visual: OrganVisual = _visuals_by_organ.get(organ)
		if is_instance_valid(existing_visual):
			existing_visual.set_visual_size(_get_organ_size_px(organ))
		return

	var visual: OrganVisual = organ_visual_scene.instantiate() as OrganVisual
	if visual == null:
		push_error("organ_visual_scene must instantiate OrganVisual.")
		return

	drag_overlay.add_child(visual)
	visual.setup(organ, _get_organ_size_px(organ))
	visual.z_index = 10
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_visuals_by_organ[organ] = visual


func _sync_visual_targets(force_snap: bool = false) -> void:
	if _inventory == null:
		return

	for organ: OrganInstance in _visuals_by_organ:
		var visual: OrganVisual = _visuals_by_organ.get(organ)

		if not is_instance_valid(visual):
			continue

		if organ == _dragged_organ:
			visual.visible = false
			continue

		if _inventory.is_organ_installed(organ):
			visual.visible = true
			visual.set_visual_size(_get_organ_size_px(organ))

			var installed_overlay_position: Vector2 = (
				canvas_to_overlay_local(
					_grid_view.get_organ_canvas_center(organ)
				)
			)

			if force_snap:
				visual.snap_to_overlay_position(
					installed_overlay_position,
					0.0
				)
			else:
				visual.follow_overlay_position(
					installed_overlay_position,
					0.0
				)

			continue

		if _pile.has_loose_organ(organ):
			visual.visible = true
			visual.set_visual_size(_get_organ_size_px(organ))

			var pile_overlay_position: Vector2 = (
				canvas_to_overlay_local(
					_pile.get_body_canvas_center(organ)
				)
			)

			if force_snap:
				visual.snap_to_overlay_position(
					pile_overlay_position,
					_pile.get_body_rotation(organ)
				)
			else:
				visual.follow_overlay_position(
					pile_overlay_position,
					_pile.get_body_rotation(organ)
				)

			continue

		visual.visible = false


func _get_organ_size_px(organ: OrganInstance) -> Vector2:
	if organ == null or organ.definition == null:
		return Vector2(48.0, 48.0)

	var cell_size: Vector2 = _grid_view.get_cell_size()

	return Vector2(
		cell_size.x * float(organ.definition.grid_width_cells),
		cell_size.y * float(organ.definition.grid_height_cells)
	)


func snap_organ_to_current_target(organ: OrganInstance) -> void:
	var visual: OrganVisual = _visuals_by_organ.get(organ)

	if not is_instance_valid(visual):
		return

	if _inventory == null:
		return

	if _inventory.is_organ_installed(organ):
		visual.visible = true
		visual.set_visual_size(_get_organ_size_px(organ))
		visual.snap_to_overlay_position(
			canvas_to_overlay_local(
				_grid_view.get_organ_canvas_center(organ)
			),
			0.0
		)
		return

	if _pile.has_loose_organ(organ):
		visual.visible = true
		visual.set_visual_size(_get_organ_size_px(organ))
		visual.snap_to_overlay_position(
			canvas_to_overlay_local(
				_pile.get_body_canvas_center(organ)
			),
			_pile.get_body_rotation(organ)
		)
		return

	visual.visible = false


func viewport_to_overlay_local(
	viewport_position: Vector2
) -> Vector2:
	return (
		drag_overlay.get_global_transform_with_canvas().affine_inverse()
		* viewport_position
	)


func canvas_to_overlay_local(
	canvas_position: Vector2
) -> Vector2:
	return (
		drag_overlay.get_global_transform_with_canvas().affine_inverse()
		* canvas_position
	)


func _on_state_changed(_organ: OrganInstance = null) -> void:
	_refresh_visuals()
	_sync_visual_targets(true)
