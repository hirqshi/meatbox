class_name WorldInteractable
extends Area3D


func try_interact(_receiver: Node) -> bool:
	push_error(
		"WorldInteractable '%s' must override try_interact()."
		% name
	)
	return false


func is_auto_interaction_enabled() -> bool:
	return false
