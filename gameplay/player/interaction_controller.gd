class_name InteractionController
extends Node

@export var interactor: PlayerInteractor

var _owner_body: CharacterBody3D
var _current_interactable: WorldInteractable
var _is_enabled: bool = true


func setup(owner_body: CharacterBody3D) -> void:
	assert(
		owner_body != null,
		"InteractionController requires a CharacterBody3D."
	)
	assert(
		interactor != null,
		"InteractionController requires a PlayerInteractor."
	)

	_owner_body = owner_body

	interactor.interactable_entered.connect(
		_on_interactable_entered
	)
	interactor.interactable_exited.connect(
		_on_interactable_exited
	)


func set_is_enabled(value: bool) -> void:
	_is_enabled = value


func handle_input(event: InputEvent) -> void:
	if not _is_enabled:
		return

	if _owner_body == null:
		return

	if not event.is_action_pressed(&"interact"):
		return

	if not is_instance_valid(_current_interactable):
		return

	_current_interactable.try_interact(_owner_body)


func _on_interactable_entered(
	interactable: WorldInteractable
) -> void:
	if not is_instance_valid(interactable):
		return

	if is_instance_valid(_current_interactable):
		return

	_current_interactable = interactable


func _on_interactable_exited(
	interactable: WorldInteractable
) -> void:
	if interactable != _current_interactable:
		return

	_current_interactable = null
	_select_next_interactable()


func _select_next_interactable() -> void:
	var interactables: Array[WorldInteractable] = (
		interactor.get_interactables()
	)

	for interactable: WorldInteractable in interactables:
		if not is_instance_valid(interactable):
			continue

		_current_interactable = interactable
		return
