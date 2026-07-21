class_name Main
extends Control

@onready var _gameplay_viewport: SubViewport = (
	$ScreenSplit/GameplayFrame/GameplayViewportContainer/GameplayViewport
)

@onready var _game_root: GameRoot = (
	$ScreenSplit/GameplayFrame/GameplayViewportContainer/GameplayViewport/GameRoot
)

@onready var _pickup_manipulator_presenter: PickupManipulatorPresenter = (
	$ScreenSplit/HudRoot/PickupManipulatorPresenter
)

@onready var _weapon_hotbar: WeaponHotbar = (
	$ScreenSplit/HudRoot/WeaponHotbar
)

@onready var _ammo_presenter: AmmoPresenter = (
	$ScreenSplit/HudRoot/AmmoPresenter
)

@onready var _inventory_hud: InventoryHud = (
	$ScreenSplit/HudRoot/InventoryHud
)

@onready var _damage_direction_indicator: DamageDirectionIndicator = (
	$ScreenSplit/HudRoot/CrosshairRoot/DamageDirectionIndicator
)

@onready var _crosshair_controller: CrosshairController = (
	$ScreenSplit/HudRoot/CrosshairRoot/CrosshairController
)


func _ready() -> void:
	assert(
		_gameplay_viewport != null,
		"Main requires a GameplayViewport."
	)
	assert(
		_game_root != null,
		"Main requires a GameRoot."
	)
	assert(
		_pickup_manipulator_presenter != null,
		"Main requires a PickupManipulatorPresenter."
	)
	assert(
		_weapon_hotbar != null,
		"Main requires a WeaponHotbar."
	)
	assert(
		_ammo_presenter != null,
		"Main requires an AmmoPresenter."
	)
	assert(
		_inventory_hud != null,
		"Main requires an InventoryHud."
	)
	assert(
		_damage_direction_indicator != null,
		"Main requires a DamageDirectionIndicator."
	)
	assert(
		_crosshair_controller != null,
		"Main requires a CrosshairController."
	)

	_game_root.player_ready.connect(_on_game_root_player_ready)

	_pickup_manipulator_presenter.setup(
		_game_root.get_world_pickup_spawner()
	)

	var player: CharacterBody3D = _game_root.get_player()

	if player != null:
		_on_game_root_player_ready(player)


func _on_game_root_player_ready(player: CharacterBody3D) -> void:
	var weapon_controller: WeaponController = (
		player.get_node_or_null("WeaponController")
		as WeaponController
	)

	assert(
		weapon_controller != null,
		"Player requires a WeaponController."
	)

	_weapon_hotbar.setup(weapon_controller)
	_ammo_presenter.setup(player)
	_damage_direction_indicator.setup(player)
	_crosshair_controller.setup(player)

	var organ_inventory: OrganInventoryComponent = (
		player.get_node_or_null("OrganInventoryComponent")
		as OrganInventoryComponent
	)

	assert(
		organ_inventory != null,
		"Player requires an OrganInventoryComponent."
	)

	_inventory_hud.setup(organ_inventory)
