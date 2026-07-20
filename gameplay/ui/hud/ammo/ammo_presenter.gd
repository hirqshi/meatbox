class_name AmmoPresenter
extends Control

@onready var _ammo_label: Label = $AmmoLabel

var _weapon_controller: WeaponController


func setup(player: CharacterBody3D) -> void:
	if player == null:
		return

	var weapon_controller: WeaponController = (
		player.get_node_or_null("WeaponController")
		as WeaponController
	)

	if weapon_controller == null:
		push_error("AmmoPresenter requires Player/WeaponController.")
		return

	if _weapon_controller != null:
		if _weapon_controller.active_weapon_changed.is_connected(
			_on_active_weapon_changed
		):
			_weapon_controller.active_weapon_changed.disconnect(
				_on_active_weapon_changed
			)

		if _weapon_controller.active_weapon_ammo_changed.is_connected(
			_on_active_weapon_ammo_changed
		):
			_weapon_controller.active_weapon_ammo_changed.disconnect(
				_on_active_weapon_ammo_changed
			)

	_weapon_controller = weapon_controller

	_weapon_controller.active_weapon_changed.connect(
		_on_active_weapon_changed
	)
	_weapon_controller.active_weapon_ammo_changed.connect(
		_on_active_weapon_ammo_changed
	)

	_update_ammo_label(
		_weapon_controller.get_active_weapon()
	)


func _on_active_weapon_changed(
	_active_slot_index: int,
	weapon: WeaponInstance
) -> void:
	_update_ammo_label(weapon)


func _on_active_weapon_ammo_changed(
	weapon: WeaponInstance,
	_current_ammo: int,
	_reserve_ammo: int
) -> void:
	_update_ammo_label(weapon)


func _update_ammo_label(
	weapon: WeaponInstance
) -> void:
	if weapon == null:
		_ammo_label.text = "-"
		return

	if not weapon.definition.uses_ammo:
		_ammo_label.text = "-"
		return

	_ammo_label.text = "%d / %d" % [
		weapon.current_ammo,
		weapon.reserve_ammo,
	]
