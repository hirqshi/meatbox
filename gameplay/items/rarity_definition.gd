class_name RarityDefinition
extends Resource

@export var rarity: ItemRarity.Type = ItemRarity.Type.COMMON
@export var display_name: String = "Common"
@export var color: Color = Color(0.75, 0.75, 0.75, 1.0)
@export_range(0.0, 2.0, 0.01) var pickup_outline_width_px: float = 1.5
