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

@export_category("Rarity")
@export var rarity: ItemRarity.Type = ItemRarity.Type.COMMON

@export_category("Fire")
@export var firing_mode: FiringMode = FiringMode.HITSCAN

@export_range(
	0.0,
	100000.0,
	0.1,
	"suffix:m"
) var range_m: float = 100.0

@export_range(
	0.0,
	100000.0,
	0.1,
	"suffix:damage"
) var damage: float = 1.0

@export_range(
	0.01,
	1000.0,
	0.01,
	"suffix:shots/s"
) var fire_rate_shots_per_second: float = 8.0

const HIT_MASK_WORLD_AND_ENEMY_HURTBOX: int = (
	(1 << 0)
	| (1 << 2)
)

@export_flags_3d_physics var hit_collision_mask: int = (
	HIT_MASK_WORLD_AND_ENEMY_HURTBOX
)

@export_category("Ammo")
@export var uses_ammo: bool = false

@export_range(0, 100000, 1)
var magazine_size: int = 0

@export_range(0, 100000, 1)
var initial_reserve_ammo: int = 0

@export_range(0, 100000, 1)
var max_reserve_ammo: int = 0

@export_range(
	0.0,
	60.0,
	0.01,
	"suffix:s"
) var reload_duration_s: float = 0.0

@export_category("World Pickup")
@export var pickup_presentation: PickupPresentationDefinition

@export_category("Inventory Presentation")
@export var inventory_icon: Texture2D


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
		return (
			"magazine_size must be greater than zero "
			+ "when uses_ammo is enabled."
		)
		
	if uses_ammo and max_reserve_ammo <= 0:
		return (
			"max_reserve_ammo must be greater than zero "
			+ "when uses_ammo is enabled."
		)

	if initial_reserve_ammo < 0:
		return "initial_reserve_ammo must not be negative."

	if initial_reserve_ammo > max_reserve_ammo:
		return (
			"initial_reserve_ammo must not exceed "
			+ "max_reserve_ammo."
		)
		
	if uses_ammo and reload_duration_s <= 0.0:
		return (
			"reload_duration_s must be greater than zero "
			+ "when uses_ammo is enabled."
		)

	return ""


func get_pickup_validation_error() -> String:
	var weapon_error: String = get_validation_error()

	if not weapon_error.is_empty():
		return weapon_error

	if pickup_presentation == null:
		return "pickup_presentation must not be null."

	var presentation_error: String = (
		pickup_presentation.get_validation_error()
	)

	if not presentation_error.is_empty():
		return (
			"Invalid pickup_presentation: %s"
			% presentation_error
		)

	if inventory_icon == null:
		return "inventory_icon must not be null."

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()


func is_valid_pickup() -> bool:
	return get_pickup_validation_error().is_empty()
