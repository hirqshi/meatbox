class_name HealthPickupPayload
extends PickupPayload

var definition: HealthPickupDefinition
var heal_amount: float


func _init(
	initial_definition: HealthPickupDefinition,
	initial_heal_amount: float
) -> void:
	assert(
		initial_definition != null,
		"HealthPickupPayload requires a HealthPickupDefinition."
	)
	assert(
		initial_definition.is_valid(),
		"Invalid health pickup definition '%s': %s"
		% [
			initial_definition.resource_path,
			initial_definition.get_validation_error(),
		]
	)
	assert(
		initial_heal_amount > 0.0,
		"HealthPickupPayload heal amount must be greater than zero."
	)

	definition = initial_definition
	heal_amount = initial_heal_amount


func get_presentation() -> PickupPresentationDefinition:
	return definition.pickup_presentation


func get_display_name() -> String:
	return definition.display_name


func get_rarity() -> ItemRarity.Type:
	return definition.rarity


func try_apply_to(receiver: Node) -> bool:
	var player: CharacterBody3D = receiver as CharacterBody3D

	if player == null:
		return false

	var health_component: HealthComponent = (
		player.get_node_or_null("HealthComponent")
		as HealthComponent
	)

	if health_component == null:
		return false

	var restored_health: float = (
		health_component.restore_health(heal_amount)
	)

	return restored_health > 0.0
