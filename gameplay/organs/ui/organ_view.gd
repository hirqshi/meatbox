class_name OrganView
extends Control

signal organ_drag_requested(organ: OrganInstance)
signal organ_hover_started(organ: OrganInstance)
signal organ_hover_ended(organ: OrganInstance)
signal organ_clicked(organ: OrganInstance)

var _organ: OrganInstance
var _grid_view: OrganGridView
var _is_hovered: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


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

	organ_clicked.emit(_organ)
	organ_drag_requested.emit(_organ)
	accept_event()


func _on_mouse_entered() -> void:
	if _is_hovered:
		return

	_is_hovered = true
	organ_hover_started.emit(_organ)


func _on_mouse_exited() -> void:
	if not _is_hovered:
		return

	_is_hovered = false
	organ_hover_ended.emit(_organ)
