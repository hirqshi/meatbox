class_name WeaponInventory
extends RefCounted

signal inventory_changed
signal active_weapon_changed(
	active_slot_index: int,
	active_weapon: WeaponInstance
)

var _slots: Array[WeaponInstance] = []
var _active_slot_index: int = 0


func _init(
	finger_gun_definition: WeaponDefinition,
	initial_regular_slot_capacity: int = 3
) -> void:
	assert(
		finger_gun_definition != null,
		"WeaponInventory requires a finger gun definition."
	)
	assert(
		finger_gun_definition.is_valid(),
		"Invalid finger gun definition '%s': %s"
		% [
			finger_gun_definition.resource_path,
			finger_gun_definition.get_validation_error(),
		]
	)
	assert(
		initial_regular_slot_capacity >= 0,
		"WeaponInventory regular slot capacity must not be negative."
	)

	_slots.resize(initial_regular_slot_capacity + 1)
	_slots[0] = WeaponInstance.new(finger_gun_definition)


func get_slot_count() -> int:
	return _slots.size()


func get_regular_slot_capacity() -> int:
	return _slots.size() - 1


func get_active_slot_index() -> int:
	return _active_slot_index


func get_active_weapon() -> WeaponInstance:
	return _slots[_active_slot_index]


func get_weapon_at(slot_index: int) -> WeaponInstance:
	if not _is_valid_slot_index(slot_index):
		return null

	return _slots[slot_index]


func is_slot_occupied(slot_index: int) -> bool:
	return get_weapon_at(slot_index) != null


func try_add_weapon(weapon: WeaponInstance) -> bool:
	if weapon == null:
		return false

	var free_slot_index: int = _find_first_free_regular_slot()

	if free_slot_index == -1:
		return false

	_slots[free_slot_index] = weapon
	inventory_changed.emit()

	return true


func replace_weapon_at(
	slot_index: int,
	new_weapon: WeaponInstance
) -> WeaponInstance:
	if new_weapon == null:
		return null

	if slot_index <= 0 or not _is_valid_slot_index(slot_index):
		return null

	var replaced_weapon: WeaponInstance = _slots[slot_index]

	if replaced_weapon == null:
		return null

	_slots[slot_index] = new_weapon
	inventory_changed.emit()

	if slot_index == _active_slot_index:
		active_weapon_changed.emit(
			_active_slot_index,
			new_weapon
		)

	return replaced_weapon


func get_nearest_occupied_regular_slot(
	from_slot_index: int,
	direction: int = 1
) -> int:
	if direction == 0:
		return -1

	if get_regular_slot_capacity() <= 0:
		return -1

	var normalized_direction: int = signi(direction)
	var slot_count: int = _slots.size()

	for step: int in range(1, slot_count):
		var candidate_slot_index: int = posmod(
			from_slot_index + normalized_direction * step,
			slot_count
		)

		if candidate_slot_index <= 0:
			continue

		if _slots[candidate_slot_index] != null:
			return candidate_slot_index

	return -1


func select_slot(slot_index: int) -> bool:
	if not _is_valid_slot_index(slot_index):
		return false

	var weapon: WeaponInstance = _slots[slot_index]

	if weapon == null:
		return false

	if slot_index == _active_slot_index:
		return true

	_active_slot_index = slot_index
	active_weapon_changed.emit(
		_active_slot_index,
		weapon
	)

	return true


func select_next_occupied_weapon(direction: int) -> bool:
	if direction == 0:
		return false

	var normalized_direction: int = signi(direction)
	var candidate_slot_index: int = (
		_active_slot_index + normalized_direction
	)

	while _is_valid_slot_index(candidate_slot_index):
		if is_slot_occupied(candidate_slot_index):
			return select_slot(candidate_slot_index)

		candidate_slot_index += normalized_direction

	return false


func remove_active_regular_weapon() -> WeaponInstance:
	if _active_slot_index == 0:
		return null

	var removed_slot_index: int = _active_slot_index
	var removed_weapon: WeaponInstance = _slots[removed_slot_index]

	if removed_weapon == null:
		return null

	_slots[removed_slot_index] = null
	_select_fallback_weapon(removed_slot_index)

	inventory_changed.emit()

	return removed_weapon


func add_regular_slots(slot_count_to_add: int) -> void:
	assert(
		slot_count_to_add > 0,
		"WeaponInventory must add at least one regular slot."
	)

	var previous_slot_count: int = _slots.size()
	_slots.resize(previous_slot_count + slot_count_to_add)

	inventory_changed.emit()


func _find_first_free_regular_slot() -> int:
	for slot_index: int in range(1, _slots.size()):
		if _slots[slot_index] == null:
			return slot_index

	return -1


func _select_fallback_weapon(
	removed_slot_index: int
) -> void:
	var slot_count: int = _slots.size()

	for step: int in range(1, slot_count + 1):
		var candidate_slot_index: int = posmod(
			removed_slot_index - step,
			slot_count
		)

		var candidate_weapon: WeaponInstance = (
			_slots[candidate_slot_index]
		)

		if candidate_weapon == null:
			continue

		_active_slot_index = candidate_slot_index
		active_weapon_changed.emit(
			_active_slot_index,
			candidate_weapon
		)
		return

	_active_slot_index = 0
	active_weapon_changed.emit(
		_active_slot_index,
		_slots[0]
	)


func _is_valid_slot_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < _slots.size()
