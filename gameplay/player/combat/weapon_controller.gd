class_name WeaponController
extends Node

signal inventory_changed
signal active_weapon_changed(
	active_slot_index: int,
	active_weapon: WeaponInstance
)
signal weapon_replaced(
	replaced_weapon: WeaponInstance,
	new_weapon: WeaponInstance
)
signal weapon_dropped(weapon: WeaponInstance)

@export_category("Definitions")
@export var finger_gun_definition: WeaponDefinition

@export_category("Slots")
@export_range(0, 1000, 1) var initial_regular_slot_capacity: int = 3

@export_category("Pickup Behavior")
@export var equip_weapon_on_pickup: bool = true

@export_category("Dependencies")
@export var combat: PlayerCombat

var _owner_body: CharacterBody3D
var _inventory: WeaponInventory
var _is_enabled: bool = true


func setup(owner_body: CharacterBody3D) -> void:
	assert(
		owner_body != null,
		"WeaponController requires a CharacterBody3D."
	)
	assert(
		finger_gun_definition != null,
		"WeaponController requires a finger gun definition."
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
		combat != null,
		"WeaponController requires a PlayerCombat."
	)

	_owner_body = owner_body
	_inventory = WeaponInventory.new(
		finger_gun_definition,
		initial_regular_slot_capacity
	)

	_inventory.inventory_changed.connect(
		_on_inventory_changed
	)
	_inventory.active_weapon_changed.connect(
		_on_active_weapon_changed
	)

	combat.set_active_weapon(_inventory.get_active_weapon())


func set_is_enabled(value: bool) -> void:
	_is_enabled = value


func handle_input(event: InputEvent) -> void:
	if not _is_enabled or _inventory == null:
		return

	if event.is_action_pressed(&"weapon_slot_1"):
		_inventory.select_slot(0)
		return

	if event.is_action_pressed(&"weapon_slot_2"):
		_inventory.select_slot(1)
		return

	if event.is_action_pressed(&"weapon_slot_3"):
		_inventory.select_slot(2)
		return

	if event.is_action_pressed(&"weapon_slot_4"):
		_inventory.select_slot(3)
		return

	if event.is_action_pressed(&"weapon_slot_5"):
		_inventory.select_slot(4)
		return

	if event.is_action_pressed(&"weapon_slot_6"):
		_inventory.select_slot(5)
		return

	if event.is_action_pressed(&"weapon_slot_7"):
		_inventory.select_slot(6)
		return

	if event.is_action_pressed(&"weapon_slot_8"):
		_inventory.select_slot(7)
		return

	if event.is_action_pressed(&"weapon_slot_9"):
		_inventory.select_slot(8)
		return

	if event.is_action_pressed(&"weapon_slot_10"):
		_inventory.select_slot(9)
		return

	if event.is_action_pressed(&"drop_weapon"):
		try_drop_active_regular_weapon()
		return

	var mouse_button_event: InputEventMouseButton = (
		event as InputEventMouseButton
	)

	if mouse_button_event == null:
		return

	if not mouse_button_event.pressed:
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_inventory.select_next_occupied_weapon(-1)
		return

	if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_inventory.select_next_occupied_weapon(1)


func get_inventory() -> WeaponInventory:
	return _inventory


func get_active_weapon() -> WeaponInstance:
	if _inventory == null:
		return null

	return _inventory.get_active_weapon()


func try_accept_weapon(new_weapon: WeaponInstance) -> bool:
	if _inventory == null or new_weapon == null:
		return false

	if _inventory.try_add_weapon(new_weapon):
		if equip_weapon_on_pickup:
			var added_slot_index: int = (
				_find_weapon_slot_index(new_weapon)
			)

			if added_slot_index != -1:
				_inventory.select_slot(added_slot_index)

		return true

	var replacement_slot_index: int = _inventory.get_active_slot_index()

	if replacement_slot_index == 0:
		replacement_slot_index = (
			_inventory.get_nearest_occupied_regular_slot(
				replacement_slot_index,
				1
			)
		)

	if replacement_slot_index == -1:
		return false

	var replaced_weapon: WeaponInstance = (
		_inventory.replace_weapon_at(
			replacement_slot_index,
			new_weapon
		)
	)

	if replaced_weapon == null:
		return false

	if equip_weapon_on_pickup:
		_inventory.select_slot(replacement_slot_index)

	weapon_replaced.emit(replaced_weapon, new_weapon)

	return true


func try_drop_active_regular_weapon() -> bool:
	if _inventory == null:
		return false

	var dropped_weapon: WeaponInstance = (
		_inventory.remove_active_regular_weapon()
	)

	if dropped_weapon == null:
		return false

	weapon_dropped.emit(dropped_weapon)

	return true


func add_regular_slots(slot_count_to_add: int) -> void:
	if _inventory == null:
		return

	_inventory.add_regular_slots(slot_count_to_add)


func _on_inventory_changed() -> void:
	inventory_changed.emit()


func _on_active_weapon_changed(
	active_slot_index: int,
	active_weapon: WeaponInstance
) -> void:
	combat.set_active_weapon(active_weapon)
	active_weapon_changed.emit(
		active_slot_index,
		active_weapon
	)


func _find_weapon_slot_index(weapon: WeaponInstance) -> int:
	if weapon == null:
		return -1

	for slot_index: int in range(
		_inventory.get_slot_count()
	):
		if _inventory.get_weapon_at(slot_index) == weapon:
			return slot_index

	return -1
