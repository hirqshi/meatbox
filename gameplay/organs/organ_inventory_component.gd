class_name OrganInventoryComponent
extends Node

signal organ_installed(
	organ: OrganInstance,
	grid_position: Vector2i
)

signal organ_removed(organ: OrganInstance)
signal loose_organ_added(organ: OrganInstance)
signal loose_organ_removed(organ: OrganInstance)
signal organ_grid_changed

@export_category("Grid")

@export_range(1, 20, 1)
var columns: int = 4

@export_range(1, 20, 1)
var rows: int = 5

var _grid: OrganGridModel
var _stat_modifiers: PlayerStatModifiers
var _loose_organs: Array[OrganInstance] = []


func _ready() -> void:
	_grid = OrganGridModel.new(columns, rows)
	_grid.changed.connect(_on_grid_changed)


func setup(
	stat_modifiers: PlayerStatModifiers
) -> void:
	assert(
		stat_modifiers != null,
		"OrganInventoryComponent requires PlayerStatModifiers."
	)

	_stat_modifiers = stat_modifiers
	_recalculate_organ_bonuses()


func get_grid() -> OrganGridModel:
	return _grid


func get_loose_organs() -> Array[OrganInstance]:
	return _loose_organs.duplicate()


func try_move_organ_to_loose(
	organ: OrganInstance
) -> bool:
	if organ == null:
		return false

	if not _grid.remove(organ):
		print(
			"Cannot move '%s' to loose: not found in grid."
			% organ.definition.display_name
		)
		return false

	_loose_organs.append(organ)
	print(
		"Moved '%s' to loose. Loose count: %d"
		% [
			organ.definition.display_name,
			_loose_organs.size()
		]
	)
	
	organ_removed.emit(organ)
	loose_organ_added.emit(organ)
	return true


func try_install_loose_organ(
	organ: OrganInstance,
	grid_position: Vector2i
) -> bool:
	if organ == null:
		return false

	if not _loose_organs.has(organ):
		return false

	if not _grid.try_place(organ, grid_position):
		return false

	_loose_organs.erase(organ)

	loose_organ_removed.emit(organ)
	organ_installed.emit(organ, grid_position)
	return true


func try_install_organ(
	organ: OrganInstance,
	grid_position: Vector2i
) -> bool:
	if organ == null:
		return false

	var was_installed: bool = _grid.try_place(
		organ,
		grid_position
	)

	if not was_installed:
		return false

	organ_installed.emit(organ, grid_position)
	return true


func try_remove_organ(
	organ: OrganInstance
) -> bool:
	if organ == null:
		return false

	var was_removed: bool = _grid.remove(organ)

	if not was_removed:
		return false

	organ_removed.emit(organ)
	return true


func remove_loose_organ(
	organ: OrganInstance
) -> bool:
	if organ == null:
		return false

	if not _loose_organs.has(organ):
		return false

	_loose_organs.erase(organ)
	loose_organ_removed.emit(organ)
	return true


func resize_grid(
	new_columns: int,
	new_rows: int
) -> bool:
	return _grid.resize(new_columns, new_rows)


func _on_grid_changed() -> void:
	_recalculate_organ_bonuses()
	organ_grid_changed.emit()


func _recalculate_organ_bonuses() -> void:
	if _stat_modifiers == null:
		return

	var max_health_bonus: float = 0.0
	var move_speed_bonus_m_per_s: float = 0.0
	var jump_velocity_bonus_m_per_s: float = 0.0

	for organ: OrganInstance in _grid.get_installed_organs():
		if organ == null or organ.definition == null:
			continue

		max_health_bonus += (
			organ.definition.max_health_bonus
		)
		move_speed_bonus_m_per_s += (
			organ.definition.move_speed_bonus_m_per_s
		)
		jump_velocity_bonus_m_per_s += (
			organ.definition.jump_velocity_bonus_m_per_s
		)

	_stat_modifiers.set_organ_bonuses(
		max_health_bonus,
		move_speed_bonus_m_per_s,
		jump_velocity_bonus_m_per_s
	)
