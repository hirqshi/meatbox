class_name OrganInstance
extends RefCounted

var definition: OrganDefinition
var freshness: float = 1.0
var rarity: ItemRarity.Type

var rotation_index: int = 0


func _init(
	organ_definition: OrganDefinition,
	organ_rarity: ItemRarity.Type,
	initial_freshness: float = 1.0
) -> void:
	assert(
		organ_definition != null,
		"OrganInstance requires an OrganDefinition."
	)
	assert(
		organ_definition.is_valid(),
		"Invalid OrganDefinition '%s': %s"
		% [
			organ_definition.resource_path,
			organ_definition.get_validation_error(),
		]
	)

	definition = organ_definition
	rarity = organ_rarity
	freshness = clampf(initial_freshness, 0.0, 1.0)


func set_rotation_index(value: int) -> void:
	rotation_index = posmod(value, 4)


func rotate_clockwise() -> void:
	rotation_index = posmod(rotation_index + 1, 4)


func rotate_counterclockwise() -> void:
	rotation_index = posmod(rotation_index - 1, 4)


func get_rotation_radians() -> float:
	return deg_to_rad(float(rotation_index * 90))
