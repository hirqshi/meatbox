class_name OrganPile
extends Control

const PILE_COLLISION_LAYER: int = 2
const WALL_THICKNESS_PX: float = 24.0

signal organ_drag_requested(organ: OrganInstance)

@export_category("Scenes")
@export var organ_pile_body_scene: PackedScene

@export_range(0.0, 2000.0, 1.0, "suffix:px/s²")
var gravity_px_per_s2: float = 900.0

@export_range(0.1, 8.0, 0.01)
var global_collision_scale: float = 1.0

@onready var _bounds: StaticBody2D = $Bounds
@onready var _items: Node2D = $Items

var _inventory: OrganInventoryComponent
var _grid_view: OrganGridView
var _bodies_by_organ: Dictionary[OrganInstance, OrganPileBody] = {}
var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _suppress_auto_add_counter: int = 0


func _ready() -> void:
	assert(
		organ_pile_body_scene != null,
		"OrganPile requires organ_pile_body_scene."
	)
	assert(_bounds != null, "OrganPile requires Bounds.")
	assert(_items != null, "OrganPile requires Items.")

	mouse_filter = Control.MOUSE_FILTER_STOP
	_random.randomize()

	_bounds.collision_layer = PILE_COLLISION_LAYER
	_bounds.collision_mask = PILE_COLLISION_LAYER

	resized.connect(_on_resized)
	_rebuild_bounds()


func setup(
	inventory: OrganInventoryComponent,
	grid_view: OrganGridView
) -> void:
	assert(inventory != null, "OrganPile requires inventory.")
	assert(grid_view != null, "OrganPile requires grid_view.")

	_disconnect_inventory()

	_inventory = inventory
	_grid_view = grid_view

	_inventory.loose_organ_added.connect(_on_loose_organ_added)
	_inventory.loose_organ_removed.connect(_on_loose_organ_removed)

	if not _grid_view.resized.is_connected(_on_grid_view_resized):
		_grid_view.resized.connect(_on_grid_view_resized)

	_sync_bodies()
	_rebuild_bounds()


func has_loose_organ(organ: OrganInstance) -> bool:
	var body: OrganPileBody = _bodies_by_organ.get(organ)
	return is_instance_valid(body)


func set_body_active(
	organ: OrganInstance,
	is_active: bool
) -> void:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if not is_instance_valid(body):
		return

	body.visible = is_active
	body.input_pickable = is_active

	if is_active:
		body.collision_layer = PILE_COLLISION_LAYER
		body.collision_mask = PILE_COLLISION_LAYER
		body.freeze = false
		body.sleeping = false
	else:
		body.collision_layer = 0
		body.collision_mask = 0
		body.linear_velocity = Vector2.ZERO
		body.angular_velocity = 0.0
		body.sleeping = true
		body.freeze = true


func restore_loose_organ_at_viewport_position(
	organ: OrganInstance,
	organ_center_viewport_position: Vector2,
	release_velocity: Vector2
) -> void:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if not is_instance_valid(body):
		return

	var items_local_position: Vector2 = (
		viewport_to_items_local_position(organ_center_viewport_position)
	)
	var body_canvas_position: Vector2 = (
		_items.get_global_transform_with_canvas() * items_local_position
	)

	set_body_active(organ, true)

	body.teleport_and_release(
		body_canvas_position,
		organ.get_rotation_radians(),
		release_velocity,
		_random.randf_range(-2.5, 2.5)
	)


func restore_loose_organ_at_viewport_position_and_wait(
	organ: OrganInstance,
	organ_center_viewport_position: Vector2,
	release_velocity: Vector2
) -> void:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if not is_instance_valid(body):
		return

	var pile_local_position: Vector2 = viewport_to_local_position(
		organ_center_viewport_position
	)
	var items_local_position: Vector2 = pile_local_position - _items.position
	var body_global_position: Vector2 = (
		get_global_transform_with_canvas() * items_local_position
	)

	set_body_active(organ, true)

	body.teleport_and_release(
		body_global_position,
		organ.get_rotation_radians(),
		release_velocity,
		_random.randf_range(-2.5, 2.5)
	)

	await body.teleport_applied


func ensure_loose_organ_body_at_viewport_position(
	organ: OrganInstance,
	organ_center_viewport_position: Vector2
) -> void:
	if organ == null:
		return

	if _bodies_by_organ.has(organ):
		return

	var items_local_position: Vector2 = (
		viewport_to_items_local_position(organ_center_viewport_position)
	)

	_add_body(
		organ,
		items_local_position,
		organ.get_rotation_radians()
	)


func get_body_viewport_center(organ: OrganInstance) -> Vector2:
	return get_body_canvas_center(organ)


func get_body_center_to_viewport_point_offset(
	organ: OrganInstance,
	viewport_position: Vector2
) -> Vector2:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if not is_instance_valid(body):
		return Vector2.ZERO

	var body_center_viewport: Vector2 = get_body_viewport_center(organ)
	return viewport_position - body_center_viewport


func get_body_rotation(organ: OrganInstance) -> float:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if not is_instance_valid(body):
		return 0.0

	return body.rotation


func get_body_rotation_radians(organ: OrganInstance) -> float:
	return get_body_rotation(organ)


func is_viewport_point_inside_pile(
	viewport_position: Vector2
) -> bool:
	var local_point: Vector2 = viewport_to_local_position(viewport_position)
	return Rect2(Vector2.ZERO, size).has_point(local_point)


func viewport_to_local_position(
	viewport_position: Vector2
) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func viewport_to_items_local(
	viewport_position: Vector2
) -> Vector2:
	var pile_local: Vector2 = viewport_to_local_position(viewport_position)
	return pile_local - _items.position


func sync_body_sizes() -> void:
	_refresh_body_sizes()


func _sync_bodies() -> void:
	if _inventory == null:
		return

	var loose_organs: Array[OrganInstance] = _inventory.get_loose_organs()

	var existing_organs: Array[OrganInstance] = []
	existing_organs.assign(_bodies_by_organ.keys())

	for organ: OrganInstance in existing_organs:
		if loose_organs.has(organ):
			continue

		_remove_body(organ)

	for organ: OrganInstance in loose_organs:
		if _bodies_by_organ.has(organ):
			continue

		_add_body(organ)


func _add_body(
	organ: OrganInstance,
	initial_position: Vector2 = Vector2.INF,
	initial_rotation: float = 0.0
) -> void:
	if organ == null or organ.definition == null:
		return

	if _bodies_by_organ.has(organ):
		return

	var body: OrganPileBody = (
		organ_pile_body_scene.instantiate() as OrganPileBody
	)

	if body == null:
		push_error("organ_pile_body_scene must instantiate OrganPileBody.")
		return

	body.visible = false
	_items.add_child(body)

	body.setup(
		organ,
		_get_organ_size_px(organ),
		gravity_px_per_s2,
		self,
		global_collision_scale
	)

	body.collision_layer = PILE_COLLISION_LAYER
	body.collision_mask = PILE_COLLISION_LAYER

	if initial_position == Vector2.INF:
		body.position = _get_spawn_position(organ)
	else:
		body.position = initial_position

	body.rotation = initial_rotation
	body.visible = true
	_bodies_by_organ[organ] = body


func _remove_body(organ: OrganInstance) -> void:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if is_instance_valid(body):
		body.queue_free()

	_bodies_by_organ.erase(organ)


func _get_spawn_position(organ: OrganInstance) -> Vector2:
	var organ_size_px: Vector2 = _get_organ_size_px(organ)
	var min_x: float = organ_size_px.x * 0.5
	var max_x: float = maxf(size.x - organ_size_px.x * 0.5, min_x)

	return Vector2(
		_random.randf_range(min_x, max_x),
		24.0
	)


func _get_organ_size_px(organ: OrganInstance) -> Vector2:
	if organ == null or organ.definition == null:
		return Vector2(48.0, 48.0)

	if _grid_view == null:
		return Vector2(48.0, 48.0)

	return _grid_view.get_organ_base_pixel_size(organ)


func _rebuild_bounds() -> void:
	if not is_instance_valid(_bounds):
		return

	for child: Node in _bounds.get_children():
		child.queue_free()

	var half_wall: float = WALL_THICKNESS_PX * 0.5

	_add_wall(
		Vector2(size.x * 0.5, -half_wall),
		Vector2(
			size.x + WALL_THICKNESS_PX * 2.0,
			WALL_THICKNESS_PX
		)
	)
	_add_wall(
		Vector2(size.x * 0.5, size.y + half_wall),
		Vector2(
			size.x + WALL_THICKNESS_PX * 2.0,
			WALL_THICKNESS_PX
		)
	)
	_add_wall(
		Vector2(-half_wall, size.y * 0.5),
		Vector2(
			WALL_THICKNESS_PX,
			size.y + WALL_THICKNESS_PX * 2.0
		)
	)
	_add_wall(
		Vector2(size.x + half_wall, size.y * 0.5),
		Vector2(
			WALL_THICKNESS_PX,
			size.y + WALL_THICKNESS_PX * 2.0
		)
	)


func _add_wall(
	wall_position: Vector2,
	wall_size: Vector2
) -> void:
	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle_shape: RectangleShape2D = RectangleShape2D.new()

	rectangle_shape.size = wall_size
	collision_shape.shape = rectangle_shape
	collision_shape.position = wall_position

	_bounds.add_child(collision_shape)


func _refresh_body_sizes() -> void:
	for organ: OrganInstance in _bodies_by_organ:
		var body: OrganPileBody = _bodies_by_organ.get(organ)

		if not is_instance_valid(body):
			continue

		body.set_global_collision_scale(global_collision_scale)
		body.set_body_size(_get_organ_size_px(organ))


func _disconnect_inventory() -> void:
	if _inventory == null:
		return

	if _inventory.loose_organ_added.is_connected(
		_on_loose_organ_added
	):
		_inventory.loose_organ_added.disconnect(
			_on_loose_organ_added
		)

	if _inventory.loose_organ_removed.is_connected(
		_on_loose_organ_removed
	):
		_inventory.loose_organ_removed.disconnect(
			_on_loose_organ_removed
		)


func _on_loose_organ_added(organ: OrganInstance) -> void:
	if _suppress_auto_add_counter > 0:
		return

	_add_body(organ)


func _on_loose_organ_removed(organ: OrganInstance) -> void:
	_remove_body(organ)


func begin_suppress_auto_add() -> void:
	_suppress_auto_add_counter += 1


func end_suppress_auto_add() -> void:
	_suppress_auto_add_counter = maxi(_suppress_auto_add_counter - 1, 0)
	

func _on_resized() -> void:
	_rebuild_bounds()


func _on_grid_view_resized() -> void:
	_rebuild_bounds()
	_refresh_body_sizes()


func _try_pick_body_at_local_point(
	local_point: Vector2
) -> OrganPileBody:
	var canvas_point: Vector2 = get_global_transform_with_canvas() * local_point
	var best_body: OrganPileBody = null
	var best_z_index: int = -2147483648

	for organ: OrganInstance in _bodies_by_organ:
		var body: OrganPileBody = _bodies_by_organ.get(organ)

		if not is_instance_valid(body):
			continue

		if not body.visible:
			continue

		if not body.input_pickable:
			continue

		var body_local_point: Vector2 = body.to_local(canvas_point)
		var half_size: Vector2 = body.get_body_size() * 0.5
		var body_rect: Rect2 = Rect2(-half_size, body.get_body_size())

		if not body_rect.has_point(body_local_point):
			continue

		if best_body == null or body.z_index >= best_z_index:
			best_body = body
			best_z_index = body.z_index

	return best_body


func viewport_to_items_local_position(
	viewport_position: Vector2
) -> Vector2:
	var canvas_position: Vector2 = (
		get_viewport().get_canvas_transform().affine_inverse() * viewport_position
	)
	return _items.to_local(canvas_position)


func get_body_canvas_center(organ: OrganInstance) -> Vector2:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if not is_instance_valid(body):
		return Vector2.ZERO

	return _items.get_global_transform_with_canvas() * body.position


func try_get_body_canvas_center(
	organ: OrganInstance
) -> Variant:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if not is_instance_valid(body):
		return null

	return get_global_transform_with_canvas() * (_items.position + body.position)


func try_get_body_rotation(
	organ: OrganInstance
) -> Variant:
	var body: OrganPileBody = _bodies_by_organ.get(organ)

	if not is_instance_valid(body):
		return null

	return body.rotation


func _gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	var mouse_button: InputEventMouseButton = event as InputEventMouseButton

	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return

	if not mouse_button.pressed:
		return

	var picked_body: OrganPileBody = _try_pick_body_at_local_point(
		mouse_button.position
	)

	if picked_body == null:
		return

	organ_drag_requested.emit(picked_body.get_organ())
	accept_event()
