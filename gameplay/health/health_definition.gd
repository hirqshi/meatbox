class_name HealthDefinition
extends Resource

@export_category("Health")
@export_range(1.0, 100000.0, 0.1) var max_health: float = 100.0

@export_category("Damage Protection")
@export_range(0.0, 60.0, 0.01, "suffix:s") var per_source_damage_cooldown_s: float = 0.25


func get_validation_error() -> String:
	if max_health <= 0.0:
		return "max_health must be greater than zero."

	if per_source_damage_cooldown_s < 0.0:
		return "per_source_damage_cooldown_s must not be negative."

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()
