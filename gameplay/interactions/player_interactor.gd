class_name PlayerInteractor
extends Area3D

signal interactable_entered(interactable: WorldInteractable)
signal interactable_exited(interactable: WorldInteractable)

var _receiver: Node
var _interactables: Array[WorldInteractable] = []


func setup(receiver: Node) -> void:
	assert(receiver != null, "PlayerInteractor requires a receiver.")

	_receiver = receiver


func get_receiver() -> Node:
	return _receiver


func get_interactables() -> Array[WorldInteractable]:
	return _interactables.duplicate()


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _on_area_entered(area: Area3D) -> void:
	var interactable: WorldInteractable = area as WorldInteractable

	if interactable == null:
		return

	if _interactables.has(interactable):
		return

	_interactables.append(interactable)
	interactable_entered.emit(interactable)


func _on_area_exited(area: Area3D) -> void:
	var interactable: WorldInteractable = area as WorldInteractable

	if interactable == null:
		return

	if not _interactables.has(interactable):
		return

	_interactables.erase(interactable)
	interactable_exited.emit(interactable)
