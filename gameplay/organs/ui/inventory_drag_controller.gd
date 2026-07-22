class_name InventoryDragController
extends Node

enum DragSourceType {
	GRID,
	PILE,
}

var _inventory: OrganInventoryComponent
var _grid_view: OrganGridView
var _pile: OrganPile
var _visual_manager: OrganVisualManager

var _is_dragging: bool = false
var _drag_organ: OrganInstance
var _drag_source_type: DragSourceType = DragSourceType.GRID
var _pointer_viewport_position: Vector2 = Vector2.ZERO
var _last_pointer_viewport_position: Vector2 = Vector2.ZERO
var _last_drag_velocity: Vector2 = Vector2.ZERO
var _drag_grab_offset_from_center: Vector2 = Vector2.ZERO
var _is_finishing_drag: bool = false


func setup(
	inventory: OrganInventoryComponent,
	grid_view: OrganGridView,
	pile: OrganPile,
	visual_manager: OrganVisualManager
) -> void:
	assert(inventory != null, "InventoryDragController requires inventory.")
	assert(grid_view != null, "InventoryDragController requires grid_view.")
	assert(pile != null, "InventoryDragController requires pile.")
	assert(
		visual_manager != null,
		"InventoryDragController requires visual_manager."
	)

	_disconnect_signals()

	_inventory = inventory
	_grid_view = grid_view
	_pile = pile
	_visual_manager = visual_manager

	if not _grid_view.organ_drag_requested.is_connected(_on_grid_drag_requested):
		_grid_view.organ_drag_requested.connect(_on_grid_drag_requested)

	if not _pile.organ_drag_requested.is_connected(_on_pile_drag_requested):
		_pile.organ_drag_requested.connect(_on_pile_drag_requested)

	set_process(true)


func _process(delta: float) -> void:
	if not _is_dragging:
		return

	if _is_finishing_drag:
		return
		
	var pointer_viewport_position: Vector2 = (
		get_viewport().get_mouse_position()
	)
	var organ_center_viewport_position: Vector2 = (
		pointer_viewport_position - _drag_grab_offset_from_center
	)

	if delta > 0.0:
		_last_drag_velocity = (
			pointer_viewport_position - _last_pointer_viewport_position
		) / delta

	_last_pointer_viewport_position = pointer_viewport_position
	_pointer_viewport_position = pointer_viewport_position

	_visual_manager.update_drag_proxy(
		organ_center_viewport_position,
		0.0
	)

	if _grid_view.is_viewport_point_over_grid(pointer_viewport_position):
		_grid_view.update_drop_preview_for_viewport_position(
			_drag_organ,
			pointer_viewport_position
		)
	else:
		_grid_view.clear_drop_preview()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	_finish_drag(pointer_viewport_position)


func _begin_drag(
	organ: OrganInstance,
	source_type: DragSourceType
) -> void:
	if organ == null:
		return

	var pointer_viewport_position: Vector2 = (
		get_viewport().get_mouse_position()
	)

	_is_dragging = true
	_drag_organ = organ
	_drag_source_type = source_type
	_pointer_viewport_position = pointer_viewport_position
	_last_pointer_viewport_position = pointer_viewport_position
	_last_drag_velocity = Vector2.ZERO
	_drag_grab_offset_from_center = Vector2.ZERO

	match source_type:
		DragSourceType.GRID:
			_drag_grab_offset_from_center = (
				pointer_viewport_position
				- _grid_view.get_organ_viewport_center(organ)
			)

		DragSourceType.PILE:
			_drag_grab_offset_from_center = (
				pointer_viewport_position
				- _pile.get_body_viewport_center(organ)
			)

	_visual_manager.set_dragged_organ(organ)
	_visual_manager.update_drag_proxy(
		pointer_viewport_position - _drag_grab_offset_from_center,
		0.0
	)
	_visual_manager.play_drag_pickup_feedback()
	
	match source_type:
		DragSourceType.GRID:
			_grid_view.set_organ_visible(organ, false)

		DragSourceType.PILE:
			_pile.set_body_active(organ, false)

	_grid_view.clear_drop_preview()


func _finish_drag(viewport_position: Vector2) -> void:
	var organ: OrganInstance = _drag_organ

	if organ == null:
		_reset_drag()
		return

	_is_finishing_drag = true

	var dropped_on_grid: bool = (
		_grid_view.is_viewport_point_over_grid(viewport_position)
		and _grid_view.can_place_organ_at_viewport_position(
			organ,
			viewport_position
		)
	)

	var dropped_on_pile: bool = _pile.is_viewport_point_inside_pile(
		viewport_position
	)

	var did_install_to_grid: bool = false

	if dropped_on_grid:
		did_install_to_grid = _commit_to_grid(organ, viewport_position)
	elif dropped_on_pile:
		_commit_to_pile(organ, viewport_position)
	else:
		_commit_to_world(organ, viewport_position)

	if did_install_to_grid:
		await _visual_manager.play_grid_insert_animation()

	_reset_drag()


func _commit_to_grid(
	organ: OrganInstance,
	viewport_position: Vector2
) -> bool:
	var target_position: Vector2i = (
		_grid_view.get_drop_grid_position_from_viewport_point(
			viewport_position,
			organ
		)
	)

	match _drag_source_type:
		DragSourceType.GRID:
			var moved_inside_grid: bool = (
				_inventory.try_install_organ(
					organ,
					target_position
				)
			)

			if not moved_inside_grid:
				_grid_view.set_organ_visible(organ, true)

			return moved_inside_grid

		DragSourceType.PILE:
			var installed_from_pile: bool = (
				_inventory.try_install_loose_organ(
					organ,
					target_position
				)
			)

			if not installed_from_pile:
				_pile.restore_loose_organ_at_viewport_position(
					organ,
					viewport_position - _drag_grab_offset_from_center,
					Vector2.ZERO
				)

			return installed_from_pile

	return false


func _commit_to_pile(
	organ: OrganInstance,
	viewport_position: Vector2
) -> void:
	var organ_center_viewport_position: Vector2 = (
		viewport_position - _drag_grab_offset_from_center
	)

	match _drag_source_type:
		DragSourceType.GRID:
			var moved_to_pile: bool = (
				_inventory.try_move_organ_to_loose(organ)
			)

			if moved_to_pile:
				_pile.restore_loose_organ_at_viewport_position(
					organ,
					organ_center_viewport_position,
					_last_drag_velocity
				)
			else:
				_grid_view.set_organ_visible(organ, true)

		DragSourceType.PILE:
			_pile.restore_loose_organ_at_viewport_position(
				organ,
				organ_center_viewport_position,
				_last_drag_velocity
			)


func _commit_to_world(
	organ: OrganInstance,
	viewport_position: Vector2
) -> void:
	match _drag_source_type:
		DragSourceType.GRID:
			var removed_from_grid: bool = _inventory.try_remove_organ(organ)

			if not removed_from_grid:
				_grid_view.set_organ_visible(organ, true)

		DragSourceType.PILE:
			var removed_from_pile: bool = _inventory.remove_loose_organ(organ)

			if not removed_from_pile:
				_pile.restore_loose_organ_at_viewport_position(
					organ,
					viewport_position - _drag_grab_offset_from_center,
					_last_drag_velocity
				)


func _reset_drag() -> void:
	if _drag_organ != null:
		if _inventory.is_organ_installed(_drag_organ):
			_grid_view.set_organ_visible(_drag_organ, true)

		if _inventory.has_loose_organ(_drag_organ):
			_pile.set_body_active(_drag_organ, true)

	_visual_manager.clear_dragged_organ()
	_visual_manager.sync_visual_targets(true)
	_grid_view.clear_drop_preview()

	_is_dragging = false
	_drag_organ = null
	_drag_source_type = DragSourceType.GRID
	_pointer_viewport_position = Vector2.ZERO
	_last_pointer_viewport_position = Vector2.ZERO
	_last_drag_velocity = Vector2.ZERO
	_drag_grab_offset_from_center = Vector2.ZERO
	
	_is_finishing_drag = false


func _on_grid_drag_requested(organ: OrganInstance) -> void:
	if _is_dragging or organ == null:
		return

	_begin_drag(organ, DragSourceType.GRID)


func _on_pile_drag_requested(organ: OrganInstance) -> void:
	if _is_dragging or organ == null:
		return

	_begin_drag(organ, DragSourceType.PILE)


func _disconnect_signals() -> void:
	if _grid_view != null:
		if _grid_view.organ_drag_requested.is_connected(
			_on_grid_drag_requested
		):
			_grid_view.organ_drag_requested.disconnect(
				_on_grid_drag_requested
			)

	if _pile != null:
		if _pile.organ_drag_requested.is_connected(
			_on_pile_drag_requested
		):
			_pile.organ_drag_requested.disconnect(
				_on_pile_drag_requested
			)
