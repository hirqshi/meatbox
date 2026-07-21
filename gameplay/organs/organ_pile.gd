class_name OrganPile
extends Control

const PILE_COLLISION_LAYER: int = 2
const WALL_THICKNESS_PX: float = 24.0

signal organ_world_drop_requested(
	organ: OrganInstance,
	screen_position: Vector2
)

@export_category("Scenes")
@export var organ_pile_item_scene: PackedScene

@export_range(0.0, 2000.0, 1.0, "suffix:px/s²")
var gravity_px_per_s2: float = 900.0

@onready var _bounds: StaticBody2D = $Bounds
@onready var _items: Node2D = $Items

var _inventory: OrganInventoryComponent
var _grid_view: OrganGridView
var _items_by_organ: Dictionary[OrganInstance, OrganPileItem] = {}
var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	assert(
		organ_pile_item_scene != null,
		"OrganPile requires organ_pile_item_scene."
	)
	assert(
		_bounds != null,
		"OrganPile requires a Bounds StaticBody2D."
	)
	assert(
		_items != null,
		"OrganPile requires an Items Node2D."
	)
	
	mouse_filter = Control.MOUSE_FILTER_PASS

	z_index = 0
	_items.z_index = 20
	
	_random.randomize()

	_bounds.collision_layer = PILE_COLLISION_LAYER
	_bounds.collision_mask = PILE_COLLISION_LAYER

	resized.connect(_on_resized)
	_rebuild_bounds()


func setup(
	inventory: OrganInventoryComponent,
	grid_view: OrganGridView
) -> void:
	assert(
		inventory != null,
		"OrganPile requires OrganInventoryComponent."
	)
	assert(
		grid_view != null,
		"OrganPile requires OrganGridView."
	)

	_disconnect_inventory()

	_inventory = inventory
	_grid_view = grid_view
	
	print(
	"OrganPile setup. Loose organs: %d"
	% _inventory.get_loose_organs().size()
	)

	_inventory.loose_organ_added.connect(_on_loose_organ_added)
	_inventory.loose_organ_removed.connect(_on_loose_organ_removed)

	if not _grid_view.resized.is_connected(
		_on_grid_view_resized
	):
		_grid_view.resized.connect(_on_grid_view_resized)

	_sync_items()
	_rebuild_bounds()


func _can_drop_data(
	_at_position: Vector2,
	data: Variant
) -> bool:
	var drag_data: OrganDragData = data as OrganDragData

	if drag_data == null or drag_data.organ == null:
		return false

	return (
		drag_data.source_type
		== OrganDragData.SourceType.GRID
		or drag_data.source_type
		== OrganDragData.SourceType.PILE
	)


func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:
	var drag_data: OrganDragData = data as OrganDragData

	if drag_data == null or drag_data.organ == null:
		print("OrganPile drop rejected: invalid drag data.")
		return

	print(
		"OrganPile received drop: %s, source: %s"
		% [
			drag_data.organ.definition.display_name,
			OrganDragData.SourceType.keys()[
				drag_data.source_type
			]
		]
	)

	if drag_data.source_type == OrganDragData.SourceType.PILE:
		return

	if _inventory == null:
		print("OrganPile drop rejected: inventory is null.")
		return

	var was_moved: bool = _inventory.try_move_organ_to_loose(
		drag_data.organ
	)

	print(
		"Move to loose result: %s"
		% was_moved
	)


func _sync_items() -> void:
	if _inventory == null:
		return

	var loose_organs: Array[OrganInstance] = (
		_inventory.get_loose_organs()
	)

	var existing_organs: Array[OrganInstance] = []
	existing_organs.assign(_items_by_organ.keys())

	for organ: OrganInstance in existing_organs:
		if loose_organs.has(organ):
			continue

		_remove_item(organ)

	for organ: OrganInstance in loose_organs:
		if _items_by_organ.has(organ):
			continue

		_add_item(organ)


func _add_item(organ: OrganInstance) -> void:
	if organ == null or organ.definition == null:
		return

	if _items_by_organ.has(organ):
		return

	var pile_item: OrganPileItem = (
		organ_pile_item_scene.instantiate()
		as OrganPileItem
	)

	if pile_item == null:
		push_error(
			"organ_pile_item_scene must instantiate OrganPileItem."
		)
		return

	_items.add_child(pile_item)

	pile_item.setup(
		organ,
		_get_organ_size_px(organ),
		gravity_px_per_s2
	)

	pile_item.collision_layer = PILE_COLLISION_LAYER
	pile_item.collision_mask = PILE_COLLISION_LAYER
	pile_item.position = _get_spawn_position(organ)

	pile_item.world_drop_requested.connect(
		_on_pile_item_world_drop_requested
	)

	_items_by_organ[organ] = pile_item
	
	print(
		"Organ spawned: %s at %s, pile size: %s"
		% [
			organ.definition.display_name,
			pile_item.position,
			size
		]
	)

func _remove_item(organ: OrganInstance) -> void:
	var pile_item: OrganPileItem = _items_by_organ.get(organ)

	if is_instance_valid(pile_item):
		pile_item.queue_free()

	_items_by_organ.erase(organ)


func _get_spawn_position(
	organ: OrganInstance
) -> Vector2:
	var organ_size_px: Vector2 = _get_organ_size_px(organ)

	var min_x: float = organ_size_px.x * 0.5
	var max_x: float = maxf(
		size.x - organ_size_px.x * 0.5,
		min_x
	)

	return Vector2(
		_random.randf_range(min_x, max_x),
		24.0
	)


func _get_organ_size_px(
	organ: OrganInstance
) -> Vector2:
	if organ == null or organ.definition == null:
		return Vector2(48.0, 48.0)

	if _grid_view == null:
		return Vector2(48.0, 48.0)

	var cell_size: Vector2 = _grid_view.get_cell_size()

	return Vector2(
		cell_size.x * float(organ.definition.grid_width_cells),
		cell_size.y * float(organ.definition.grid_height_cells)
	)


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
	var collision_shape: CollisionShape2D = (
		CollisionShape2D.new()
	)
	var rectangle_shape: RectangleShape2D = (
		RectangleShape2D.new()
	)

	rectangle_shape.size = wall_size
	collision_shape.shape = rectangle_shape
	collision_shape.position = wall_position

	_bounds.add_child(collision_shape)


func _refresh_item_sizes() -> void:
	for organ: OrganInstance in _items_by_organ:
		var pile_item: OrganPileItem = (
			_items_by_organ.get(organ)
		)

		if not is_instance_valid(pile_item):
			continue

		pile_item.set_organ_size_px(
			_get_organ_size_px(organ)
		)


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


func _on_loose_organ_added(
	organ: OrganInstance
) -> void:
	print(
		"Loose organ added: %s"
		% organ.definition.display_name
	)

	_add_item(organ)


func _on_loose_organ_removed(
	organ: OrganInstance
) -> void:
	_remove_item(organ)


func _on_pile_item_world_drop_requested(
	organ: OrganInstance,
	screen_position: Vector2
) -> void:
	organ_world_drop_requested.emit(organ, screen_position)


func _on_resized() -> void:
	_rebuild_bounds()


func _on_grid_view_resized() -> void:
	_rebuild_bounds()
	_refresh_item_sizes()
