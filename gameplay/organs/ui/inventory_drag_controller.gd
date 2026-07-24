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
var _is_finishing_drag: bool = false

var _drag_organ: OrganInstance
var _drag_source_type: DragSourceType = DragSourceType.GRID

var _pointer_viewport_position: Vector2 = Vector2.ZERO
var _last_pointer_viewport_position: Vector2 = Vector2.ZERO
var _last_drag_velocity: Vector2 = Vector2.ZERO
var _drag_grab_offset_from_center: Vector2 = Vector2.ZERO

var _drag_anchor_cell_base_local: Vector2i = Vector2i.ZERO

var _is_waiting_for_pile_teleport: bool = false
var _pending_pile_visual_center: Vector2 = Vector2.ZERO


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
	set_process_unhandled_input(true)


func _process(delta: float) -> void:
	if not _is_dragging:
		return

	if _is_finishing_drag:
		if _is_waiting_for_pile_teleport and _drag_organ != null:
			_visual_manager.update_drag_visual_at(
				_pending_pile_visual_center,
				_drag_organ.get_rotation_radians()
			)
		return

	var pointer_viewport_position: Vector2 = get_viewport().get_mouse_position()
	var organ_center_viewport_position: Vector2 = (
		pointer_viewport_position - _drag_grab_offset_from_center
	)

	if delta > 0.0:
		_last_drag_velocity = (
			pointer_viewport_position - _last_pointer_viewport_position
		) / delta

	_last_pointer_viewport_position = pointer_viewport_position
	_pointer_viewport_position = pointer_viewport_position

	_visual_manager.update_drag_visual(
		organ_center_viewport_position
	)

	if _grid_view.is_viewport_point_over_grid(pointer_viewport_position):
		_grid_view.update_drop_preview_for_viewport_position(
			_drag_organ,
			pointer_viewport_position,
			_get_drag_anchor_cell_local()
		)
	else:
		_grid_view.clear_drop_preview()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	_finish_drag(pointer_viewport_position)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_dragging:
		return

	if _is_finishing_drag:
		return

	var mouse_button_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_button_event == null or not mouse_button_event.pressed:
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_rotate_drag_counterclockwise()
		get_viewport().set_input_as_handled()
	elif mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_rotate_drag_clockwise()
		get_viewport().set_input_as_handled()


func _begin_drag(
	organ: OrganInstance,
	source_type: DragSourceType
) -> void:
	if organ == null or organ.definition == null:
		return

	var pointer_viewport_position: Vector2 = get_viewport().get_mouse_position()

	_is_dragging = true
	_is_finishing_drag = false
	_is_waiting_for_pile_teleport = false
	_pending_pile_visual_center = Vector2.ZERO
	_drag_organ = organ
	_drag_source_type = source_type
	_pointer_viewport_position = pointer_viewport_position
	_last_pointer_viewport_position = pointer_viewport_position
	_last_drag_velocity = Vector2.ZERO
	_drag_grab_offset_from_center = Vector2.ZERO
	_drag_anchor_cell_base_local = Vector2i.ZERO

	match source_type:
		DragSourceType.GRID:
			_drag_grab_offset_from_center = (
				pointer_viewport_position
				- _grid_view.get_organ_viewport_center(organ)
			)

			var grabbed_rotated_local_cell: Vector2i = (
				_grid_view.get_local_cell_from_viewport_point_for_organ(
					organ,
					pointer_viewport_position
				)
			)

			_drag_anchor_cell_base_local = (
				OrganFootprint.rotate_local_cell(
					grabbed_rotated_local_cell,
					-organ.rotation_index
				)
			)

		DragSourceType.PILE:
			_drag_grab_offset_from_center = (
				_pile.get_body_center_to_viewport_point_offset(
					organ,
					pointer_viewport_position
				)
			)

			var snapped_rotation_index: int = (
				_angle_radians_to_rotation_index(
					_pile.get_body_rotation_radians(organ)
				)
			)

			organ.set_rotation_index(snapped_rotation_index)
			_drag_anchor_cell_base_local = Vector2i.ZERO

	_visual_manager.set_dragged_organ(organ)
	_visual_manager.rotate_drag_visual_to(
		organ.get_rotation_radians(),
		false
	)
	_visual_manager.play_drag_pickup_feedback()

	_grid_view.set_organ_visible(organ, false)
	_pile.set_body_active(organ, false)

	_grid_view.clear_drop_preview()


func _finish_drag(viewport_position: Vector2) -> void:
	var organ: OrganInstance = _drag_organ

	if organ == null:
		_reset_drag()
		return

	_is_finishing_drag = true

	var drag_anchor_cell_local: Vector2i = _get_drag_anchor_cell_local()

	var dropped_on_grid: bool = (
		_grid_view.is_viewport_point_over_grid(viewport_position)
		and _grid_view.can_place_organ_at_viewport_position(
			organ,
			viewport_position,
			drag_anchor_cell_local
		)
	)

	var dropped_on_pile: bool = _pile.is_viewport_point_inside_pile(
		viewport_position
	)

	var did_install_to_grid: bool = false

	if dropped_on_grid:
		did_install_to_grid = _commit_to_grid(
			organ,
			viewport_position,
			drag_anchor_cell_local
		)
	elif dropped_on_pile:
		await _commit_to_pile(organ, viewport_position)
	else:
		_commit_to_world(organ, viewport_position)

	if did_install_to_grid:
		await _visual_manager.play_grid_insert_animation()

	_reset_drag()


func _commit_to_grid(
	organ: OrganInstance,
	viewport_position: Vector2,
	drag_anchor_cell_local: Vector2i
) -> bool:
	var target_position: Vector2i = (
		_grid_view.get_drop_grid_position_from_viewport_point(
			viewport_position,
			drag_anchor_cell_local
		)
	)

	match _drag_source_type:
		DragSourceType.GRID:
			var moved_inside_grid: bool = (
				_inventory.try_install_organ(organ, target_position)
			)

			if not moved_inside_grid:
				_grid_view.set_organ_visible(organ, true)

			return moved_inside_grid

		DragSourceType.PILE:
			var installed_from_pile: bool = (
				_inventory.try_install_loose_organ(organ, target_position)
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

	if _drag_source_type == DragSourceType.PILE:
		var drag_visual_center: Vector2 = (
			_visual_manager.get_drag_visual_viewport_center()
		)

		if drag_visual_center != Vector2.ZERO:
			organ_center_viewport_position = drag_visual_center

	match _drag_source_type:
		DragSourceType.GRID:
			_visual_manager.begin_visual_sync_suspension()
			_pile.begin_suppress_auto_add()

			var moved_to_pile: bool = (
				_inventory.try_move_organ_to_loose(organ)
			)

			if moved_to_pile:
				_pile.ensure_loose_organ_body_at_viewport_position(
					organ,
					organ_center_viewport_position
				)

				_pending_pile_visual_center = (
					organ_center_viewport_position
				)
				_is_waiting_for_pile_teleport = true

				_visual_manager.update_drag_visual_at(
					_pending_pile_visual_center,
					organ.get_rotation_radians()
				)

				await _pile.restore_loose_organ_at_viewport_position_and_wait(
					organ,
					organ_center_viewport_position,
					_last_drag_velocity
				)

				_is_waiting_for_pile_teleport = false

				if is_instance_valid(self):
					_visual_manager.snap_organ_to_current_target(organ)
			else:
				_grid_view.set_organ_visible(organ, true)

			_pile.end_suppress_auto_add()
			_visual_manager.end_visual_sync_suspension()

		DragSourceType.PILE:
			_pending_pile_visual_center = (
				organ_center_viewport_position
			)
			_is_waiting_for_pile_teleport = true

			_visual_manager.update_drag_visual_at(
				_pending_pile_visual_center,
				organ.get_rotation_radians()
			)

			await _pile.restore_loose_organ_at_viewport_position_and_wait(
				organ,
				organ_center_viewport_position,
				_last_drag_velocity
			)

			_is_waiting_for_pile_teleport = false

			if is_instance_valid(self):
				_visual_manager.snap_organ_to_current_target(organ)


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
	var released_organ: OrganInstance = _drag_organ

	_grid_view.clear_drop_preview()

	_is_dragging = false
	_is_finishing_drag = false
	_is_waiting_for_pile_teleport = false
	_pending_pile_visual_center = Vector2.ZERO
	_drag_organ = null
	_drag_source_type = DragSourceType.GRID
	_pointer_viewport_position = Vector2.ZERO
	_last_pointer_viewport_position = Vector2.ZERO
	_last_drag_velocity = Vector2.ZERO
	_drag_grab_offset_from_center = Vector2.ZERO
	_drag_anchor_cell_base_local = Vector2i.ZERO

	if released_organ == null:
		_visual_manager.clear_dragged_organ()
		return

	_restore_source_visual_ownership(released_organ)
	_visual_manager.release_dragged_organ_to_current_target(
		released_organ
	)


func _restore_source_visual_ownership(organ: OrganInstance) -> void:
	if organ == null:
		return

	if not is_instance_valid(_grid_view) or not is_instance_valid(_pile):
		return

	if _inventory.is_organ_installed(organ):
		_grid_view.set_organ_visible(organ, true)

	if _inventory.has_loose_organ(organ):
		_pile.set_body_active(organ, true)


func _rotate_drag_clockwise() -> void:
	if _drag_organ == null:
		return

	_drag_organ.rotate_clockwise()
	_visual_manager.rotate_drag_visual_to(
		_drag_organ.get_rotation_radians(),
		true
	)
	_visual_manager.play_drag_rotate_feedback(1)
	_refresh_drop_preview()


func _rotate_drag_counterclockwise() -> void:
	if _drag_organ == null:
		return

	_drag_organ.rotate_counterclockwise()
	_visual_manager.rotate_drag_visual_to(
		_drag_organ.get_rotation_radians(),
		true
	)
	_visual_manager.play_drag_rotate_feedback(-1)
	_refresh_drop_preview()


func _refresh_drop_preview() -> void:
	if _drag_organ == null:
		return

	if not _grid_view.is_viewport_point_over_grid(_pointer_viewport_position):
		_grid_view.clear_drop_preview()
		return

	_grid_view.update_drop_preview_for_viewport_position(
		_drag_organ,
		_pointer_viewport_position,
		_get_drag_anchor_cell_local()
	)


func _get_drag_anchor_cell_local() -> Vector2i:
	if _drag_organ == null:
		return Vector2i.ZERO

	return OrganFootprint.rotate_local_cell(
		_drag_anchor_cell_base_local,
		_drag_organ.rotation_index
	)


func _angle_radians_to_rotation_index(
	angle_radians: float
) -> int:
	var angle_deg: float = wrapf(rad_to_deg(angle_radians), 0.0, 360.0)
	return posmod(int(round(angle_deg / 90.0)), 4)


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
		if _grid_view.organ_drag_requested.is_connected(_on_grid_drag_requested):
			_grid_view.organ_drag_requested.disconnect(_on_grid_drag_requested)

	if _pile != null:
		if _pile.organ_drag_requested.is_connected(_on_pile_drag_requested):
			_pile.organ_drag_requested.disconnect(_on_pile_drag_requested)
