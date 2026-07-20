class_name RarityCatalog
extends Resource

@export var common: RarityDefinition
@export var uncommon: RarityDefinition
@export var rare: RarityDefinition
@export var legendary: RarityDefinition


func get_definition(
	rarity: ItemRarity.Type
) -> RarityDefinition:
	match rarity:
		ItemRarity.Type.COMMON:
			return common

		ItemRarity.Type.UNCOMMON:
			return uncommon

		ItemRarity.Type.RARE:
			return rare

		ItemRarity.Type.LEGENDARY:
			return legendary

	push_error("Unsupported item rarity: %s." % rarity)
	return common
