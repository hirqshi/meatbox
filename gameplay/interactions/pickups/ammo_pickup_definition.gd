class_name AmmoPickupDefinition
extends Resource

@export_category("Identity")
@export var pickup_id: StringName
@export var display_name: String

@export_category("Rarity")
@export var rarity: ItemRarity.Type = ItemRarity.Type.COMMON

@export_category("Compatibility")
@export var is_universal: bool = true

@export var compatible_weapon_ids: Array[StringName] = []

@export_category("Pickup Presentation")
@export var pickup_presentation: PickupPresentationDefinition


func is_compatible_with(
	weapon_definition: WeaponDefinition
) -> bool:
	if weapon_definition == null:
		return false

	if is_universal:
		return true

	return compatible_weapon_ids.has(
		weapon_definition.weapon_id
	)


func get_validation_error() -> String:
	if pickup_id.is_empty():
		return "pickup_id must not be empty."

	if display_name.is_empty():
		return "display_name must not be empty."

	if not is_universal and compatible_weapon_ids.is_empty():
		return (
			"compatible_weapon_ids must not be empty "
			+ "when is_universal is disabled."
		)

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

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()
