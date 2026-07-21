class_name OrganInstance
extends RefCounted

var definition: OrganDefinition
var freshness: float = 1.0
var rarity: ItemRarity.Type


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
