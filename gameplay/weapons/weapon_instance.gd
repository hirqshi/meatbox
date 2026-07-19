class_name WeaponInstance
extends RefCounted

var definition: WeaponDefinition
var current_ammo: int
var next_fire_time_s: float = 0.0


func _init(initial_definition: WeaponDefinition) -> void:
	assert(initial_definition != null, "WeaponInstance requires a WeaponDefinition.")
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

	next_fire_time_s = current_time_s + _get_fire_interval_s()


func _get_fire_interval_s() -> float:
	return 1.0 / definition.fire_rate_shots_per_second
