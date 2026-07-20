class_name WeaponPickupPayload
extends PickupPayload

var weapon: WeaponInstance


func _init(initial_weapon: WeaponInstance) -> void:
	assert(
		initial_weapon != null,
		"WeaponPickupPayload requires a WeaponInstance."
	)
	assert(
		initial_weapon.definition != null,
		"WeaponPickupPayload weapon requires a WeaponDefinition."
	)
	assert(
		initial_weapon.definition.is_valid_pickup(),
		"Invalid weapon pickup definition '%s': %s"
		% [
			initial_weapon.definition.resource_path,
			initial_weapon.definition.get_pickup_validation_error(),
		]
	)

	weapon = initial_weapon


func get_presentation() -> PickupPresentationDefinition:
	return weapon.definition.pickup_presentation


func get_display_name() -> String:
	return weapon.definition.display_name


func get_rarity() -> ItemRarity.Type:
	return weapon.definition.rarity


func try_apply_to(receiver: Node) -> bool:
	var player: CharacterBody3D = receiver as CharacterBody3D

	if player == null:
		return false

	var weapon_controller: WeaponController = (
		player.get_node_or_null("WeaponController")
		as WeaponController
	)

	if weapon_controller == null:
		return false

	return weapon_controller.try_accept_weapon(weapon)
