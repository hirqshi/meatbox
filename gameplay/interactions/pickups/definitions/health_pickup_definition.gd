class_name HealthPickupDefinition
extends PickupDefinition

@export_category("Health")
@export_range(
	0.1,
	100000.0,
	0.1,
	"suffix:hp"
) var default_heal_amount: float = 25.0


func get_validation_error() -> String:
	var base_error: String = super.get_validation_error()

	if not base_error.is_empty():
		return base_error

	if default_heal_amount <= 0.0:
		return "default_heal_amount must be greater than zero."

	return ""
