class_name WeaponInstance
extends RefCounted

signal ammo_changed(
	current_ammo: int,
	reserve_ammo: int
)

var definition: WeaponDefinition
var current_ammo: int
var reserve_ammo: int
var next_fire_time_s: float = 0.0


func _init(initial_definition: WeaponDefinition) -> void:
	assert(
		initial_definition != null,
		"WeaponInstance requires a WeaponDefinition."
	)
	assert(
		initial_definition.is_valid(),
		"Invalid weapon definition '%s': %s"
		% [
			initial_definition.resource_path,
			initial_definition.get_validation_error(),
		]
	)

	definition = initial_definition
	current_ammo = definition.magazine_size
	reserve_ammo = definition.initial_reserve_ammo


func can_fire(current_time_s: float) -> bool:
	if current_time_s < next_fire_time_s:
		return false

	if definition.uses_ammo and current_ammo <= 0:
		return false

	return true


func consume_shot(current_time_s: float) -> void:
	assert(can_fire(current_time_s), "Weapon cannot fire yet.")

	if definition.uses_ammo:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, reserve_ammo)

	next_fire_time_s = current_time_s + _get_fire_interval_s()


func add_reserve_ammo(amount: int) -> int:
	if not definition.uses_ammo:
		return 0

	if amount <= 0:
		return 0

	var free_reserve_ammo: int = (
		definition.max_reserve_ammo
		- reserve_ammo
	)

	if free_reserve_ammo <= 0:
		return 0

	var accepted_amount: int = mini(
		amount,
		free_reserve_ammo
	)

	reserve_ammo += accepted_amount
	ammo_changed.emit(current_ammo, reserve_ammo)

	return accepted_amount


func reload() -> bool:
	if not definition.uses_ammo:
		return false

	if current_ammo >= definition.magazine_size:
		return false

	if reserve_ammo <= 0:
		return false

	var missing_magazine_ammo: int = (
		definition.magazine_size
		- current_ammo
	)

	var transferred_ammo: int = mini(
		missing_magazine_ammo,
		reserve_ammo
	)

	current_ammo += transferred_ammo
	reserve_ammo -= transferred_ammo

	ammo_changed.emit(current_ammo, reserve_ammo)

	return true


func _get_fire_interval_s() -> float:
	return 1.0 / definition.fire_rate_shots_per_second
