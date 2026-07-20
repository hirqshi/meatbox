class_name HealthPickupDefinition
extends Resource

@export_category("Identity")
@export var pickup_id: StringName
@export var display_name: String

@export_category("Health")
@export_range(
	0.1,
	100000.0,
	0.1,
	"suffix:hp"
) var default_heal_amount: float = 25.0

@export_category("Pickup Presentation")
@export var pickup_presentation: PickupPresentationDefinition


func get_validation_error() -> String:
	if pickup_id.is_empty():
		return "pickup_id must not be empty."

	if display_name.is_empty():
		return "display_name must not be empty."

	if default_heal_amount <= 0.0:
		return "default_heal_amount must be greater than zero."

	if pickup_presentation == null:
		return "pickup_presentation must not be null."

	var presentation_error: String = (
		pickup_presentation.get_validation_error()
	)

	if not presentation_error.is_empty():
		return (
			"Invalid pickup_presentation: %s"
			% presentation_error
		)

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()
