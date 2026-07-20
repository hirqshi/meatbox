class_name PickupPayload
extends RefCounted


func get_presentation() -> PickupPresentationDefinition:
	push_error(
		"PickupPayload '%s' must override get_presentation()."
		% get_script().resource_path
	)
	return null


func get_display_name() -> String:
	push_error(
		"PickupPayload '%s' must override get_display_name()."
		% get_script().resource_path
	)
	return "Unnamed pickup"


func try_apply_to(_receiver: Node) -> bool:
	push_error(
		"PickupPayload '%s' must override try_apply_to()."
		% get_script().resource_path
	)
	return false
