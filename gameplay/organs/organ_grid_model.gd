class_name OrganGridModel
extends RefCounted

signal changed

var columns: int
var rows: int

var _cells: Array[OrganInstance] = []
var _placements: Dictionary[OrganInstance, Vector2i] = {}


func _init(
	grid_columns: int = 4,
	grid_rows: int = 5
) -> void:
	assert(
		grid_columns > 0,
		"OrganGridModel columns must be greater than zero."
	)
	assert(
		grid_rows > 0,
		"OrganGridModel rows must be greater than zero."
	)

	columns = grid_columns
	rows = grid_rows
	_cells.resize(columns * rows)


func resize(
	grid_columns: int,
	grid_rows: int
) -> bool:
	if grid_columns <= 0 or grid_rows <= 0:
		return false

	var existing_organs: Array[OrganInstance] = (
		get_installed_organs()
	)
	var existing_positions: Dictionary[OrganInstance, Vector2i] = (
		_placements.duplicate()
	)

	columns = grid_columns
	rows = grid_rows

	_cells.clear()
	_cells.resize(columns * rows)
	_placements.clear()

	for organ: OrganInstance in existing_organs:
		var grid_position: Vector2i = (
			existing_positions.get(
				organ,
				Vector2i(-1, -1)
			)
		)

		if not _try_place_without_signal(
			organ,
			grid_position
		):
			push_warning(
				"Organ '%s' no longer fits after grid resize."
				% organ.definition.display_name
			)

	changed.emit()
	return true


func try_place(
	organ: OrganInstance,
	grid_position: Vector2i
) -> bool:
	var was_placed: bool = _try_place_without_signal(
		organ,
		grid_position
	)

	if was_placed:
		changed.emit()

	return was_placed


func can_place(
	organ: OrganInstance,
	grid_position: Vector2i
) -> bool:
	if organ == null or organ.definition == null:
		return false

	for cell: Vector2i in get_occupied_cells(
		organ,
		grid_position
	):
		if not is_cell_inside(cell):
			return false

		var occupying_organ: OrganInstance = (
			_cells[_get_cell_index(cell)]
		)

		if (
			occupying_organ != null
			and occupying_organ != organ
		):
			return false

	return true


func remove(organ: OrganInstance) -> bool:
	if organ == null or not _placements.has(organ):
		return false

	var grid_position: Vector2i = (
		_placements.get(
			organ,
			Vector2i(-1, -1)
		)
	)

	_clear_organ_cells(organ, grid_position)
	_placements.erase(organ)

	changed.emit()
	return true


func get_position(
	organ: OrganInstance
) -> Vector2i:
	if organ == null:
		return Vector2i(-1, -1)

	return _placements.get(
		organ,
		Vector2i(-1, -1)
	)


func get_installed_organs() -> Array[OrganInstance]:
	var organs: Array[OrganInstance] = []

	for organ: OrganInstance in _placements.keys():
		organs.append(organ)

	return organs


func get_occupied_cells(
	organ: OrganInstance,
	grid_position: Vector2i
) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	if organ == null or organ.definition == null:
		return cells

	var footprint_cells: Array[Vector2i] = (
		organ.definition.get_footprint_cells(
			organ.rotation_index
		)
	)

	for local_cell: Vector2i in footprint_cells:
		cells.append(grid_position + local_cell)

	return cells


func is_cell_inside(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < columns
		and cell.y >= 0
		and cell.y < rows
	)


func _try_place_without_signal(
	organ: OrganInstance,
	grid_position: Vector2i
) -> bool:
	if organ == null:
		return false

	var previous_position: Vector2i = get_position(organ)
	var was_already_placed: bool = (
		previous_position != Vector2i(-1, -1)
	)

	if was_already_placed:
		_clear_organ_cells(organ, previous_position)
		_placements.erase(organ)

	if not can_place(organ, grid_position):
		if was_already_placed:
			_placements[organ] = previous_position

			for cell: Vector2i in get_occupied_cells(
				organ,
				previous_position
			):
				_cells[_get_cell_index(cell)] = organ

		return false

	_placements[organ] = grid_position

	for cell: Vector2i in get_occupied_cells(
		organ,
		grid_position
	):
		_cells[_get_cell_index(cell)] = organ

	return true


func _clear_organ_cells(
	organ: OrganInstance,
	grid_position: Vector2i
) -> void:
	for cell: Vector2i in get_occupied_cells(
		organ,
		grid_position
	):
		if not is_cell_inside(cell):
			continue

		var cell_index: int = _get_cell_index(cell)

		if _cells[cell_index] == organ:
			_cells[cell_index] = null


func _get_cell_index(cell: Vector2i) -> int:
	return cell.y * columns + cell.x
