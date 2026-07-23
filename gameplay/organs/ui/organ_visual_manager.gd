class_name OrganVisualManager
extends Node

@export_category("Scenes")
@export var organ_visual_scene: PackedScene

@export_category("Dependencies")
@export var drag_overlay: Control

@export_category("Presentation")
@export var presentation_settings: OrganPresentationSettings

var _inventory: OrganInventoryComponent
var _grid_view: OrganGridView
var _pile: OrganPile

var _visuals_by_organ: Dictionary[OrganInstance, OrganVisual] = {}
var _dragged_organ: OrganInstance = null
var _is_grid_insert_animating: bool = false

var _suspend_sync_counter: int = 0
var _is_releasing_drag_visual: bool = false


func _ready() -> void:
	if presentation_settings != null:
		if not presentation_settings.changed.is_connected(_on_presentation_settings_changed):
			presentation_settings.changed.connect(_on_presentation_settings_changed)


func setup(
	inventory: OrganInventoryComponent,
	grid_view: OrganGridView,
	pile: OrganPile
) -> void:
	assert(inventory != null, "OrganVisualManager requires inventory.")
	assert(grid_view != null, "OrganVisualManager requires grid_view.")
	assert(pile != null, "OrganVisualManager requires pile.")
	assert(organ_visual_scene != null, "OrganVisualManager requires organ_visual_scene.")
	assert(drag_overlay != null, "OrganVisualManager requires drag_overlay.")
	assert(
		presentation_settings != null,
		"OrganVisualManager requires presentation_settings."
	)

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

	_apply_presentation_settings_to_dependencies()
	_refresh_visuals()
	_sync_visual_targets(true)
	set_process(true)


func set_dragged_organ(organ: OrganInstance) -> void:
	_dragged_organ = organ

	if organ == null:
		return

	var visual: OrganVisual = _visuals_by_organ.get(organ)
	if not is_instance_valid(visual):
		return

	visual.stop_all_motion()

	var drag_scale: float = presentation_settings.global_icon_scale
	drag_scale *= presentation_settings.drag_proxy_scale_multiplier

	visual.visible = true
	visual.z_index = presentation_settings.drag_visual_z_index
	visual.set_global_icon_scale(drag_scale)
	visual.set_sizes(
		_get_drag_visual_logical_size_px(organ),
		_get_organ_display_base_size_px(organ)
	)
	visual.snap_rotation_to(organ.get_rotation_radians())


func clear_dragged_organ() -> void:
	var organ: OrganInstance = _dragged_organ
	_dragged_organ = null

	if organ == null:
		return

	var visual: OrganVisual = _visuals_by_organ.get(organ)
	if not is_instance_valid(visual):
		return

	visual.stop_all_motion()
	visual.z_index = presentation_settings.installed_visual_z_index


func release_dragged_organ_to_current_target(
	organ: OrganInstance
) -> void:
	_is_releasing_drag_visual = true

	if organ == null:
		_dragged_organ = null
		_is_releasing_drag_visual = false
		return

	var visual: OrganVisual = _visuals_by_organ.get(organ)

	if is_instance_valid(visual):
		visual.stop_all_motion()
		visual.z_index = presentation_settings.installed_visual_z_index

	_dragged_organ = null
	_sync_single_visual_target(organ, true)

	_is_releasing_drag_visual = false


func hide_dragged_visual_immediately() -> void:
	if _dragged_organ == null:
		return

	var visual: OrganVisual = _visuals_by_organ.get(_dragged_organ)
	if not is_instance_valid(visual):
		return

	visual.stop_all_motion()
	visual.visible = false


func update_drag_visual(
	viewport_position: Vector2
) -> void:
	if _dragged_organ == null:
		return

	var visual: OrganVisual = _visuals_by_organ.get(_dragged_organ)
	if not is_instance_valid(visual):
		return

	var drag_scale: float = presentation_settings.global_icon_scale
	drag_scale *= presentation_settings.drag_proxy_scale_multiplier

	visual.visible = true
	visual.z_index = presentation_settings.drag_visual_z_index
	visual.set_global_icon_scale(drag_scale)
	visual.set_sizes(
		_get_drag_visual_logical_size_px(_dragged_organ),
		_get_organ_display_base_size_px(_dragged_organ)
	)
	visual.snap_position_to_overlay_center(
		viewport_to_overlay_local(viewport_position)
	)


func get_drag_visual_viewport_center() -> Vector2:
	if _dragged_organ == null:
		return Vector2.ZERO

	var visual: OrganVisual = _visuals_by_organ.get(_dragged_organ)
	if not is_instance_valid(visual):
		return Vector2.ZERO

	return drag_overlay.get_global_transform_with_canvas() * visual.position


func rotate_drag_visual_to(
	rotation_radians: float,
	smooth: bool = true
) -> void:
	if _dragged_organ == null:
		return

	var visual: OrganVisual = _visuals_by_organ.get(_dragged_organ)
	if not is_instance_valid(visual):
		return

	if smooth:
		visual.tween_rotation_to(rotation_radians)
	else:
		visual.snap_rotation_to(rotation_radians)


func snap_organ_to_current_target_next_frame(
	organ: OrganInstance
) -> void:
	_snap_organ_to_current_target_next_frame(organ)


func _snap_organ_to_current_target_next_frame(
	organ: OrganInstance
) -> void:
	await get_tree().process_frame

	if not is_instance_valid(self):
		return

	if organ == null:
		return

	snap_organ_to_current_target(organ)


func sync_visual_targets(force_snap: bool = false) -> void:
	_sync_visual_targets(force_snap)


func _process(_delta: float) -> void:
	if _dragged_organ != null:
		return

	if _is_releasing_drag_visual:
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


func _ensure_visual(organ: OrganInstance) -> void:
	if organ == null:
		return

	if _visuals_by_organ.has(organ):
		var existing_visual: OrganVisual = _visuals_by_organ.get(organ)
		if is_instance_valid(existing_visual):
			existing_visual.set_sizes(
				_get_organ_logical_size_px(organ),
				_get_organ_display_base_size_px(organ)
			)
			existing_visual.z_index = presentation_settings.installed_visual_z_index
		return

	var visual: OrganVisual = organ_visual_scene.instantiate() as OrganVisual
	if visual == null:
		push_error("organ_visual_scene must instantiate OrganVisual.")
		return

	drag_overlay.add_child(visual)
	visual.set_global_icon_scale(presentation_settings.global_icon_scale)
	visual.setup(
		organ,
		_get_organ_logical_size_px(organ),
		_get_organ_display_base_size_px(organ)
	)
	visual.z_index = presentation_settings.installed_visual_z_index
	visual.visible = true

	_visuals_by_organ[organ] = visual


func _sync_visual_targets(force_snap: bool = false) -> void:
	if _inventory == null:
		return

	for organ: OrganInstance in _visuals_by_organ:
		_sync_single_visual_target(organ, force_snap)


func _sync_single_visual_target(
	organ: OrganInstance,
	force_snap: bool
) -> void:
	var visual: OrganVisual = _visuals_by_organ.get(organ)
	if not is_instance_valid(visual):
		return

	if organ == _dragged_organ:
		visual.visible = true
		return

	if _inventory.is_organ_installed(organ):
		visual.visible = true
		visual.z_index = presentation_settings.installed_visual_z_index
		visual.set_global_icon_scale(presentation_settings.global_icon_scale)
		visual.set_sizes(
			_get_organ_logical_size_px(organ),
			_get_organ_display_base_size_px(organ)
		)

		var installed_overlay_position: Vector2 = (
			canvas_to_overlay_local(
				_grid_view.get_organ_canvas_center(organ)
			)
		)
		var installed_rotation: float = organ.get_rotation_radians()

		if force_snap:
			visual.snap_to_overlay_position(
				installed_overlay_position,
				installed_rotation
			)
		else:
			visual.tween_to_overlay_position(
				installed_overlay_position,
				installed_rotation
			)
		return

	if _pile.has_loose_organ(organ):
		var pile_canvas_center_variant: Variant = (
			_pile.try_get_body_canvas_center(organ)
		)
		var pile_rotation_variant: Variant = (
			_pile.try_get_body_rotation(organ)
		)

		if pile_canvas_center_variant == null or pile_rotation_variant == null:
			return

		visual.visible = true
		visual.z_index = presentation_settings.installed_visual_z_index
		visual.set_global_icon_scale(presentation_settings.global_icon_scale)
		visual.set_sizes(
			_get_drag_visual_logical_size_px(organ),
			_get_organ_display_base_size_px(organ)
		)

		var pile_overlay_position: Vector2 = (
			canvas_to_overlay_local(pile_canvas_center_variant as Vector2)
		)
		var pile_rotation: float = pile_rotation_variant as float

		visual.snap_to_overlay_position(
			pile_overlay_position,
			pile_rotation
		)
		return

	visual.visible = false


func begin_visual_sync_suspension() -> void:
	_suspend_sync_counter += 1


func end_visual_sync_suspension() -> void:
	_suspend_sync_counter = maxi(_suspend_sync_counter - 1, 0)

	if _suspend_sync_counter == 0 and _dragged_organ == null:
		_sync_visual_targets(true)


func _get_organ_logical_size_px(organ: OrganInstance) -> Vector2:
	if organ == null or organ.definition == null:
		return Vector2(48.0, 48.0)

	return _grid_view.get_organ_pixel_size(organ)


func _get_drag_visual_logical_size_px(organ: OrganInstance) -> Vector2:
	if organ == null or organ.definition == null:
		return Vector2(48.0, 48.0)

	return _grid_view.get_organ_base_pixel_size(organ)


func _get_organ_display_base_size_px(organ: OrganInstance) -> Vector2:
	if organ == null or organ.definition == null:
		return Vector2(48.0, 48.0)

	return _grid_view.get_organ_base_pixel_size(organ)


func snap_organ_to_current_target(organ: OrganInstance) -> void:
	_sync_single_visual_target(organ, true)


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


func _apply_presentation_settings_to_dependencies() -> void:
	if _pile != null and presentation_settings != null:
		_pile.global_collision_scale = (
			presentation_settings.global_collision_scale
		)
		_pile.sync_body_sizes()


func _on_presentation_settings_changed() -> void:
	if not is_node_ready():
		return

	_apply_presentation_settings_to_dependencies()

	if _dragged_organ != null:
		var dragged_visual: OrganVisual = _visuals_by_organ.get(_dragged_organ)
		if is_instance_valid(dragged_visual):
			var drag_scale: float = presentation_settings.global_icon_scale
			drag_scale *= presentation_settings.drag_proxy_scale_multiplier
			dragged_visual.set_global_icon_scale(drag_scale)
			dragged_visual.set_sizes(
				_get_drag_visual_logical_size_px(_dragged_organ),
				_get_organ_display_base_size_px(_dragged_organ)
			)

	_refresh_visuals()
	_sync_visual_targets(true)


func _on_state_changed(changed_organ: OrganInstance = null) -> void:
	_refresh_visuals()

	if _suspend_sync_counter > 0:
		return

	if _is_grid_insert_animating:
		return

	if changed_organ != null and changed_organ == _dragged_organ:
		return

	_sync_visual_targets(true)


func play_hover_enter_for(organ: OrganInstance) -> void:
	if organ == _dragged_organ:
		return

	var visual: OrganVisual = _visuals_by_organ.get(organ)
	if is_instance_valid(visual):
		visual.play_hover_enter()


func play_hover_exit_for(organ: OrganInstance) -> void:
	if organ == _dragged_organ:
		return

	var visual: OrganVisual = _visuals_by_organ.get(organ)
	if is_instance_valid(visual):
		visual.play_hover_exit()


func play_click_feedback_for(organ: OrganInstance) -> void:
	if organ == _dragged_organ:
		return

	var visual: OrganVisual = _visuals_by_organ.get(organ)
	if is_instance_valid(visual):
		visual.play_click_shake()


func play_drag_pickup_feedback() -> void:
	if _dragged_organ == null:
		return

	var visual: OrganVisual = _visuals_by_organ.get(_dragged_organ)
	if is_instance_valid(visual):
		visual.play_click_shake()


func play_grid_insert_animation() -> void:
	if _dragged_organ == null:
		return

	var visual: OrganVisual = _visuals_by_organ.get(_dragged_organ)
	if not is_instance_valid(visual):
		return

	if _inventory == null or _grid_view == null:
		return

	if not _inventory.is_organ_installed(_dragged_organ):
		return

	_is_grid_insert_animating = true

	var target_overlay_position: Vector2 = (
		canvas_to_overlay_local(
			_grid_view.get_organ_canvas_center(_dragged_organ)
		)
	)

	visual.tween_to_overlay_position(
		target_overlay_position,
		_dragged_organ.get_rotation_radians()
	)

	var move_duration_sec: float = 0.12
	if (
		_dragged_organ.definition != null
		and _dragged_organ.definition.visual_definition != null
	):
		move_duration_sec = (
			_dragged_organ.definition.visual_definition.move_duration_sec
		)

	await get_tree().create_timer(move_duration_sec).timeout

	if is_instance_valid(visual):
		visual.play_insert_shake()

	var shake_duration_sec: float = 0.14
	if (
		_dragged_organ.definition != null
		and _dragged_organ.definition.visual_definition != null
	):
		shake_duration_sec = (
			_dragged_organ.definition.visual_definition.insert_shake_duration_sec
		)

	await get_tree().create_timer(shake_duration_sec).timeout

	_is_grid_insert_animating = false


func play_drag_rotate_feedback(direction: int) -> void:
	if _dragged_organ == null:
		return

	var visual: OrganVisual = _visuals_by_organ.get(_dragged_organ)
	if is_instance_valid(visual):
		visual.play_rotate_feedback(direction)
