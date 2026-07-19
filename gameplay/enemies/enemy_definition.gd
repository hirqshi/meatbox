class_name EnemyDefinition
extends Resource

@export_category("Identity")
@export var enemy_id: StringName = &"crawler"
@export var display_name: String = "Crawler"

@export_category("Movement")
@export_range(0.0, 100.0, 0.1, "suffix:m/s") var move_speed_mps: float = 4.5
@export_range(0.0, 500.0, 0.1, "suffix:m/s²") var acceleration_mps2: float = 28.0
@export_range(0.0, 500.0, 0.1, "suffix:m/s²") var deceleration_mps2: float = 40.0
@export_range(0.0, 500.0, 0.1, "suffix:m/s²") var gravity_mps2: float = 35.0

@export_category("Targeting")
@export_range(0.0, 500.0, 0.1, "suffix:m") var detection_range_m: float = 30.0
@export_range(0.01, 20.0, 0.01, "suffix:m") var body_radius_m: float = 0.45
@export_range(0.01, 20.0, 0.01, "suffix:m") var target_body_radius_m: float = 0.4
@export_range(0.0, 20.0, 0.01, "suffix:m") var attack_reach_m: float = 0.7

@export_category("Contact Attack")
@export_range(0.0, 100000.0, 0.1, "suffix:damage") var contact_damage: float = 10.0
@export_range(0.01, 60.0, 0.01, "suffix:s") var contact_attack_interval_s: float = 1.0


func get_validation_error() -> String:
	if enemy_id.is_empty():
		return "enemy_id must not be empty."

	if display_name.is_empty():
		return "display_name must not be empty."

	if move_speed_mps < 0.0:
		return "move_speed_mps must not be negative."

	if acceleration_mps2 <= 0.0:
		return "acceleration_mps2 must be greater than zero."

	if deceleration_mps2 <= 0.0:
		return "deceleration_mps2 must be greater than zero."

	if gravity_mps2 <= 0.0:
		return "gravity_mps2 must be greater than zero."

	if detection_range_m <= 0.0:
		return "detection_range_m must be greater than zero."

	if body_radius_m <= 0.0:
		return "body_radius_m must be greater than zero."

	if target_body_radius_m <= 0.0:
		return "target_body_radius_m must be greater than zero."

	if attack_reach_m < 0.0:
		return "attack_reach_m must not be negative."

	if get_contact_range_m() > detection_range_m:
		return "contact range must not exceed detection_range_m."

	if contact_damage <= 0.0:
		return "contact_damage must be greater than zero."

	if contact_attack_interval_s <= 0.0:
		return "contact_attack_interval_s must be greater than zero."

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()


func get_contact_range_m() -> float:
	return body_radius_m + target_body_radius_m + attack_reach_m
