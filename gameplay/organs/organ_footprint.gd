class_name OrganFootprint
extends Resource

@export var cells: Array[Vector2i] = [Vector2i.ZERO]:
	set(value):
		cells = _sanitize_cells(value)
		changed.emit()

@export var editor_origin: Vector2i = Vector2i.ZERO:
	set(value):
		editor_origin = value
		changed.emit()


func get_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(cells)
	return result


func get_cells_normalized() -> Array[Vector2i]:
	return _normalize_cells(cells)


func get_cells_rotated(rotation_index: int) -> Array[Vector2i]:
	var normalized_cells: Array[Vector2i] = get_cells_normalized()
	var rotated_cells: Array[Vector2i] = []

	for cell: Vector2i in normalized_cells:
		rotated_cells.append(
			_rotate_cell(cell, rotation_index)
		)

	return _normalize_cells(rotated_cells)


func get_bounds(rotation_index: int = 0) -> Rect2i:
	var rotated_cells: Array[Vector2i] = get_cells_rotated(rotation_index)

	if rotated_cells.is_empty():
		return Rect2i(0, 0, 1, 1)

	var min_x: int = rotated_cells[0].x
	var min_y: int = rotated_cells[0].y
	var max_x: int = rotated_cells[0].x
	var max_y: int = rotated_cells[0].y

	for cell: Vector2i in rotated_cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)

	return Rect2i(
		Vector2i(min_x, min_y),
		Vector2i(max_x - min_x + 1, max_y - min_y + 1)
	)


func has_cell(cell: Vector2i) -> bool:
	return cells.has(cell)


func toggle_cell(cell: Vector2i) -> void:
	var next_cells: Array[Vector2i] = get_cells()

	if next_cells.has(cell):
		next_cells.erase(cell)
	else:
		next_cells.append(cell)

	cells = _sanitize_cells(next_cells)

	if cells.is_empty():
		cells = [Vector2i.ZERO]

	changed.emit()


func clear_cells() -> void:
	cells = [Vector2i.ZERO]
	editor_origin = Vector2i.ZERO
	changed.emit()


func normalize() -> void:
	cells = _normalize_cells(cells)
	editor_origin -= _get_min_cell(cells)
	changed.emit()


func make_rectangle(size_cells: Vector2i) -> void:
	var next_cells: Array[Vector2i] = []

	var width: int = maxi(size_cells.x, 1)
	var height: int = maxi(size_cells.y, 1)

	for y: int in height:
		for x: int in width:
			next_cells.append(Vector2i(x, y))

	cells = next_cells
	editor_origin = Vector2i.ZERO
	changed.emit()


func rotate_editor_origin_clockwise() -> void:
	editor_origin = _rotate_cell(editor_origin, 1)
	changed.emit()


func rotate_editor_origin_counterclockwise() -> void:
	editor_origin = _rotate_cell(editor_origin, 3)
	changed.emit()


static func rotate_local_cell(
	cell: Vector2i,
	rotation_index: int
) -> Vector2i:
	return _rotate_cell(cell, rotation_index)


static func rotate_local_cells(
	source_cells: Array[Vector2i],
	rotation_index: int
) -> Array[Vector2i]:
	var rotated: Array[Vector2i] = []

	for cell: Vector2i in source_cells:
		rotated.append(_rotate_cell(cell, rotation_index))

	return _normalize_cells(rotated)


static func get_cells_bounds(
	source_cells: Array[Vector2i]
) -> Rect2i:
	if source_cells.is_empty():
		return Rect2i(0, 0, 1, 1)

	var min_x: int = source_cells[0].x
	var min_y: int = source_cells[0].y
	var max_x: int = source_cells[0].x
	var max_y: int = source_cells[0].y

	for cell: Vector2i in source_cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)

	return Rect2i(
		Vector2i(min_x, min_y),
		Vector2i(max_x - min_x + 1, max_y - min_y + 1)
	)


static func normalize_local_cells(
	source_cells: Array[Vector2i]
) -> Array[Vector2i]:
	return _normalize_cells(source_cells)


static func _rotate_cell(
	cell: Vector2i,
	rotation_index: int
) -> Vector2i:
	match posmod(rotation_index, 4):
		0:
			return cell
		1:
			return Vector2i(-cell.y, cell.x)
		2:
			return Vector2i(-cell.x, -cell.y)
		3:
			return Vector2i(cell.y, -cell.x)
		_:
			return cell


static func _normalize_cells(
	source_cells: Array[Vector2i]
) -> Array[Vector2i]:
	var sanitized: Array[Vector2i] = _sanitize_cells(source_cells)

	if sanitized.is_empty():
		return [Vector2i.ZERO]

	var min_cell: Vector2i = _get_min_cell(sanitized)
	var normalized: Array[Vector2i] = []

	for cell: Vector2i in sanitized:
		normalized.append(cell - min_cell)

	normalized.sort_custom(_sort_cells)

	return normalized


static func _sanitize_cells(
	source_cells: Array[Vector2i]
) -> Array[Vector2i]:
	var unique: Dictionary[Vector2i, bool] = {}

	for cell: Vector2i in source_cells:
		unique[cell] = true

	var result: Array[Vector2i] = []

	for cell: Vector2i in unique.keys():
		result.append(cell)

	result.sort_custom(_sort_cells)
	return result


static func _get_min_cell(
	source_cells: Array[Vector2i]
) -> Vector2i:
	if source_cells.is_empty():
		return Vector2i.ZERO

	var min_x: int = source_cells[0].x
	var min_y: int = source_cells[0].y

	for cell: Vector2i in source_cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)

	return Vector2i(min_x, min_y)


static func _sort_cells(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x

	return a.y < b.y
