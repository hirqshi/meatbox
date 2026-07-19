class_name WeaponDefinition
extends Resource

enum FiringMode {
	HITSCAN,
	PROJECTILE,
	MELEE,
	CUSTOM,
}

@export_category("Identity")
@export var weapon_id: StringName
@export var display_name: String

@export_category("Fire")
@export var firing_mode: FiringMode = FiringMode.HITSCAN
@export_range(0.0, 100000.0, 0.1, "suffix:m") var range_m: float = 100.0
@export_range(0.0, 100000.0, 0.1, "suffix:damage") var damage: float = 1.0
@export_range(0.01, 1000.0, 0.01, "suffix:shots/s") var fire_rate_shots_per_second: float = 8.0
@export_flags_3d_physics var hit_collision_mask: int = 5

@export_category("Ammo")
@export var uses_ammo: bool = false
@export_range(0, 100000, 1) var magazine_size: int = 0
@export_range(0.0, 60.0, 0.01, "suffix:s") var reload_duration_s: float = 0.0


func get_validation_error() -> String:
	if weapon_id.is_empty():
		return "weapon_id must not be empty."

	if display_name.is_empty():
		return "display_name must not be empty."

	if range_m <= 0.0:
		return "range_m must be greater than zero."

	if damage < 0.0:
		return "damage must not be negative."

	if fire_rate_shots_per_second <= 0.0:
		return "fire_rate_shots_per_second must be greater than zero."

	if hit_collision_mask == 0:
		return "hit_collision_mask must contain at least one layer."

	if uses_ammo and magazine_size <= 0:
		return "magazine_size must be greater than zero when uses_ammo is enabled."

	if uses_ammo and reload_duration_s <= 0.0:
		return "reload_duration_s must be greater than zero when uses_ammo is enabled."

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()
