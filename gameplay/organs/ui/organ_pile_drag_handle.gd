class_name OrganPileDragHandle
extends Control

signal drag_started
signal drag_finished(was_successful: bool)

var _pile_item: OrganPileItem


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_pile_item = get_parent() as OrganPileItem


func _get_drag_data(
	at_position: Vector2
) -> Variant:
	if _pile_item == null:
		return null

	var organ: OrganInstance = _pile_item.get_organ()

	if organ == null:
		return null

	drag_started.emit()

	var preview: Control = _create_drag_preview(
		organ,
		_pile_item.get_organ_size_px()
	)
	set_drag_preview(preview)

	return OrganDragData.new(
		organ,
		OrganDragData.SourceType.PILE,
		Vector2i.ZERO,
		null,
		_pile_item
	)


func _notification(what: int) -> void:
	if what != NOTIFICATION_DRAG_END:
		return

	drag_finished.emit(
		get_viewport().gui_is_drag_successful()
	)


func _create_drag_preview(
	organ: OrganInstance,
	preview_size: Vector2
) -> Control:
	var preview: Control = Control.new()
	var texture_rect: TextureRect = TextureRect.new()

	preview.custom_minimum_size = preview_size
	preview.size = preview_size
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	texture_rect.texture = organ.definition.icon
	texture_rect.modulate = Color(
		organ.definition.grid_tint,
		0.8
	)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	texture_rect.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	preview.add_child(texture_rect)
	return preview
