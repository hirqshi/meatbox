class_name PickupPayload
extends RefCounted


func get_definition() -> PickupDefinition:
	return null


func get_display_name() -> String:
	var definition: PickupDefinition = get_definition()

	if definition == null:
		return "Unknown pickup"

	return definition.display_name


func try_apply_to(_receiver: Node) -> bool:
	push_error(
		"PickupPayload '%s' must override try_apply_to()."
		% get_display_name()
	)
	return false


func is_auto_pickup_enabled() -> bool:
	var definition: PickupDefinition = get_definition()

	if definition == null:
		return false

	return definition.is_auto_pickup_enabled
