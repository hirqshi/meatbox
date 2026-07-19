class_name PickupInteractionArea
extends WorldInteractable


func try_interact(receiver: Node) -> bool:
	var pickup: WorldPickup = get_parent() as WorldPickup

	if pickup == null:
		push_error(
			"PickupInteractionArea '%s' requires a WorldPickup parent."
			% name
		)
		return false

	return pickup.try_interact(receiver)


func is_auto_interaction_enabled() -> bool:
	var pickup: WorldPickup = get_parent() as WorldPickup

	if pickup == null:
		return false

	return pickup.is_auto_interaction_enabled()
