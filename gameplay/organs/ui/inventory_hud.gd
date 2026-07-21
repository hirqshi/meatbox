class_name InventoryHud
extends Control

@onready var _organ_pile: OrganPile = $OrganPile
@onready var _organ_grid: OrganGridView = $OrganPile/OrganGridView
@onready var _drag_overlay: Control = $OrganPile/DragOverlay
@onready var _visual_manager: OrganVisualManager = (
	$OrganPile/OrganVisualManager
)
@onready var _drag_controller: InventoryDragController = (
	$OrganPile/InventoryDragController
)

var _organ_inventory: OrganInventoryComponent


func _ready() -> void:
	assert(_organ_pile != null, "InventoryHud requires OrganPile.")
	assert(_organ_grid != null, "InventoryHud requires OrganGrid.")
	assert(_drag_overlay != null, "InventoryHud requires DragOverlay.")
	assert(
		_visual_manager != null,
		"InventoryHud requires OrganVisualManager."
	)
	assert(
		_drag_controller != null,
		"InventoryHud requires InventoryDragController."
	)

	_drag_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(organ_inventory: OrganInventoryComponent) -> void:
	assert(
		organ_inventory != null,
		"InventoryHud requires OrganInventoryComponent."
	)

	_organ_inventory = organ_inventory

	_organ_grid.setup(_organ_inventory.get_grid())
	_organ_pile.setup(_organ_inventory, _organ_grid)

	_visual_manager.drag_overlay = _drag_overlay
	_visual_manager.setup(
		_organ_inventory,
		_organ_grid,
		_organ_pile
	)

	_drag_controller.setup(
		_organ_inventory,
		_organ_grid,
		_organ_pile,
		_visual_manager
	)


func viewport_to_drag_overlay_local(
	viewport_position: Vector2
) -> Vector2:
	return (
		_drag_overlay.get_global_transform_with_canvas().affine_inverse()
		* viewport_position
	)


func get_drag_overlay() -> Control:
	return _drag_overlay
