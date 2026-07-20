class_name InteractionController
extends Node

signal aimed_interactable_changed(
	previous: WorldInteractable,
	current: WorldInteractable
)

@export_category("Dependencies")
@export var interactor: PlayerInteractor
@export var aim_ray: RayCast3D

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
	assert(
		aim_ray != null,
		"InteractionController requires an InteractionAimRay."
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

	if not _is_enabled:
		_set_current_interactable(null)


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


func physics_update() -> void:
	if not _is_enabled:
		return

	_update_aimed_interactable()


func _update_aimed_interactable() -> void:
	aim_ray.force_raycast_update()

	if not aim_ray.is_colliding():
		_set_current_interactable(null)
		return

	var collider: Object = aim_ray.get_collider()
	var aimed_interactable: WorldInteractable = (
		collider as WorldInteractable
	)

	if aimed_interactable == null:
		_set_current_interactable(null)
		return

	if not _is_interactable_in_range(aimed_interactable):
		_set_current_interactable(null)
		return

	_set_current_interactable(aimed_interactable)


func _is_interactable_in_range(
	interactable: WorldInteractable
) -> bool:
	var interactables: Array[WorldInteractable] = (
		interactor.get_interactables()
	)

	return interactables.has(interactable)


func _set_current_interactable(
	value: WorldInteractable
) -> void:
	if _current_interactable == value:
		return

	var previous_interactable: WorldInteractable = (
		_current_interactable
	)

	_current_interactable = value

	aimed_interactable_changed.emit(
		previous_interactable,
		_current_interactable
	)


func _on_interactable_entered(
	_interactable: WorldInteractable
) -> void:
	pass


func _on_interactable_exited(
	interactable: WorldInteractable
) -> void:
	if interactable != _current_interactable:
		return

	_set_current_interactable(null)
