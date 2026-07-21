class_name OrganDragData
extends RefCounted

enum SourceType {
	GRID,
	PILE,
}

var organ: OrganInstance
var source_type: SourceType
var source_view: OrganView
var source_pile_item: OrganPileItem
var grab_offset_cells: Vector2i


func _init(
	p_organ: OrganInstance,
	p_source_type: SourceType,
	p_grab_offset_cells: Vector2i = Vector2i.ZERO,
	p_source_view: OrganView = null,
	p_source_pile_item: OrganPileItem = null
) -> void:
	organ = p_organ
	source_type = p_source_type
	grab_offset_cells = p_grab_offset_cells
	source_view = p_source_view
	source_pile_item = p_source_pile_item
