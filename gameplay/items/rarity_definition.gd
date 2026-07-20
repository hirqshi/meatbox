class_name RarityDefinition
extends Resource

@export var rarity: ItemRarity.Type = ItemRarity.Type.COMMON
@export var display_name: String = "Common"

@export_category("Outline")
@export var outline_color: Color = Color(
	0.72,
	0.72,
	0.72,
	1.0
)

@export_range(0.0, 32.0, 0.1, "suffix:px")
var glow_size_px: float = 2.0
