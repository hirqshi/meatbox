class_name OrganView
extends Control

signal organ_drag_requested(organ: OrganInstance)

var _organ: OrganInstance
var _grid_view: OrganGridView


func setup(
	organ: OrganInstance,
	grid_view: OrganGridView
) -> void:
	assert(organ != null, "OrganView requires OrganInstance.")
	assert(grid_view != null, "OrganView requires OrganGridView.")

	_organ = organ
	_grid_view = grid_view
	mouse_filter = Control.MOUSE_FILTER_STOP


func get_organ() -> OrganInstance:
	return _organ


func _gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton:
		return

	var mouse_button: InputEventMouseButton = event as InputEventMouseButton

	if mouse_button.button_index != MOUSE_BUTTON_LEFT:
		return

	if not mouse_button.pressed:
		return

	organ_drag_requested.emit(_organ)
	accept_event()
