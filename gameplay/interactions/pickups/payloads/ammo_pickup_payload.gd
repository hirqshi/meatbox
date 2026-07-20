class_name AmmoPickupPayload
extends PickupPayload

var definition: AmmoPickupDefinition
var amount: int


func _init(
	initial_definition: AmmoPickupDefinition,
	initial_amount: int
) -> void:
	assert(
		initial_definition != null,
		"AmmoPickupPayload requires an AmmoPickupDefinition."
	)
	assert(
		initial_definition.is_valid(),
		"Invalid ammo pickup definition '%s': %s"
		% [
			initial_definition.resource_path,
			initial_definition.get_validation_error(),
		]
	)
	assert(
		initial_amount > 0,
		"AmmoPickupPayload amount must be greater than zero."
	)

	definition = initial_definition
	amount = initial_amount


func get_presentation() -> PickupPresentationDefinition:
	return definition.pickup_presentation


func get_display_name() -> String:
	return "%s x%d" % [
		definition.display_name,
		amount,
	]


func get_rarity() -> ItemRarity.Type:
	return definition.rarity


func try_apply_to(receiver: Node) -> PickupApplyResult:
	var player: CharacterBody3D = receiver as CharacterBody3D

	if player == null:
		return PickupApplyResult.rejected()

	var weapon_controller: WeaponController = (
		player.get_node_or_null("WeaponController")
		as WeaponController
	)

	if weapon_controller == null:
		return PickupApplyResult.rejected()

	var accepted_amount: int = weapon_controller.try_add_ammo(
		definition,
		amount
	)

	if accepted_amount <= 0:
		return PickupApplyResult.rejected()

	amount -= accepted_amount

	if amount <= 0:
		return PickupApplyResult.consumed()

	return PickupApplyResult.partially_consumed(
		accepted_amount
	)
