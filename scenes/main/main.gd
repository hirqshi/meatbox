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

@onready var _organ_grid: OrganGridView = (
	$ScreenSplit/HudRoot/OrganPile/OrganGrid
)

@onready var _organ_pile: OrganPile = (
	$ScreenSplit/HudRoot/OrganPile
)

@onready var _damage_direction_indicator: DamageDirectionIndicator = (
	$ScreenSplit/HudRoot/CrosshairRoot/DamageDirectionIndicator
)

@onready var _crosshair_controller: CrosshairController = (
	$ScreenSplit/HudRoot/CrosshairRoot/CrosshairController
)

var _organ_inventory: OrganInventoryComponent


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
		_organ_grid != null,
		"Main requires a HudRoot/OrganGrid."
	)
	assert(
		_organ_pile != null,
		"Main requires a HudRoot/OrganPile."
	)
	assert(
		_damage_direction_indicator != null,
		"Main requires a DamageDirectionIndicator."
	)
	assert(
		_crosshair_controller != null,
		"Main requires a CrosshairController."
	)

	_game_root.player_ready.connect(
		_on_game_root_player_ready
	)

	_pickup_manipulator_presenter.setup(
		_game_root.get_world_pickup_spawner()
	)

	var player: CharacterBody3D = _game_root.get_player()

	if player != null:
		_on_game_root_player_ready(player)


func _on_game_root_player_ready(
	player: CharacterBody3D
) -> void:
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
	
	_organ_inventory = organ_inventory

	_organ_grid.setup(
		organ_inventory.get_grid(),
		organ_inventory
	)

	_organ_pile.setup(
		organ_inventory,
		_organ_grid
	)

	if not _organ_grid.organ_world_drop_requested.is_connected(
		_on_organ_world_drop_requested
	):
		_organ_grid.organ_world_drop_requested.connect(
			_on_organ_world_drop_requested
		)

	if not _organ_pile.organ_world_drop_requested.is_connected(
		_on_organ_world_drop_requested
	):
		_organ_pile.organ_world_drop_requested.connect(
			_on_organ_world_drop_requested
		)


func _on_organ_world_drop_requested(
	organ: OrganInstance,
	screen_position: Vector2
) -> void:
	if _organ_inventory == null or organ == null:
		return

	var was_removed_from_grid: bool = (
		_organ_inventory.try_move_organ_to_loose(organ)
	)

	if not was_removed_from_grid:
		var loose_organs: Array[OrganInstance] = (
			_organ_inventory.get_loose_organs()
		)

		if loose_organs.has(organ):
			_organ_inventory.remove_loose_organ(organ)

	print(
		"TODO: spawn world organ '%s' at screen position %s"
		% [
			organ.definition.display_name,
			screen_position
		]
	)
