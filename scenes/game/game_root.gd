class_name GameRoot
extends Node

signal player_ready(player: CharacterBody3D)


const PLAYER_SCENE: PackedScene = preload("res://gameplay/player/player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://gameplay/enemies/enemy.tscn")
const WORLD_PICKUP_SCENE: PackedScene = preload(
	"res://gameplay/interactions/pickups/world_pickup.tscn"
)

@export var enemy_spawn_position: Vector3 = Vector3(0.0, 1.0, -10.0)
@export var default_run_config: RunConfig
@export var health_pickup_definition: HealthPickupDefinition
@export var universal_ammo_definition: AmmoPickupDefinition
@export var pistol_definition: WeaponDefinition
@export var player_spawn_position: Vector3 = Vector3(0.0, 3.0, 0.0)

@export_category("Debug Organs")
@export var max_health_organ_definition: OrganDefinition
@export var move_speed_organ_definition: OrganDefinition
@export var jump_height_organ_definition: OrganDefinition

@onready var _gameplay_root: Node = $GameplayRoot
@onready var _world_pickup_spawner: WorldPickupSpawner = (
	$WorldPickupSpawner
)

var _player: CharacterBody3D
var _active_enemies: Array[Enemy] = []


func _ready() -> void:
	assert(default_run_config != null, "GameRoot requires a default RunConfig.")

	DeveloperConsole.log_info(
		"GameRoot ready. Seed: %d" % default_run_config.run_seed
	)
	assert(
		health_pickup_definition != null,
		"GameRoot requires a HealthPickupDefinition."
	)
	assert(
		health_pickup_definition.is_valid(),
		"Invalid health pickup definition '%s': %s"
		% [
			health_pickup_definition.resource_path,
			health_pickup_definition.get_validation_error(),
		]
	)
	assert(
		universal_ammo_definition != null,
		"GameRoot requires an AmmoPickupDefinition."
	)
	assert(
		universal_ammo_definition.is_valid(),
		"Invalid ammo pickup definition '%s': %s"
		% [
			universal_ammo_definition.resource_path,
			universal_ammo_definition.get_validation_error(),
		]
	)
	assert(
	pistol_definition != null,
	"GameRoot requires a pistol WeaponDefinition."
	)
	assert(
		pistol_definition.is_valid_pickup(),
		"Invalid pistol definition '%s': %s"
		% [
			pistol_definition.resource_path,
			pistol_definition.get_pickup_validation_error(),
		]
	)
	_validate_organ_definition(
	max_health_organ_definition,
	"max_health_organ_definition"
	)
	_validate_organ_definition(
		move_speed_organ_definition,
		"move_speed_organ_definition"
	)
	_validate_organ_definition(
		jump_height_organ_definition,
		"jump_height_organ_definition"
	)
	
	if not RunSession.is_run_active():
		RunSession.start_run(default_run_config)

	_player = _spawn_player()
	_world_pickup_spawner.setup(_player)
	_setup_player_debug(_player)
	player_ready.emit(_player)

	_register_debug_commands()


func _exit_tree() -> void:
	_unregister_debug_commands()


func _register_debug_commands() -> void:
	DeveloperConsole.register_command(
		&"damage_player",
		"Usage: damage_player <amount>.",
		_damage_player_from_console
	)
	DeveloperConsole.register_command(
		&"heal_player",
		"Usage: heal_player <amount|full>.",
		_heal_player_from_console
	)
	DeveloperConsole.register_command(
		&"kill_player",
		"Usage: kill_player.",
		_kill_player_from_console
	)
	DeveloperConsole.register_command(
		&"respawn_player",
		"Usage: respawn_player. Recreates player and clears enemies.",
		_respawn_player_from_console
	)
	DeveloperConsole.register_command(
		&"spawn_enemy",
		"Usage: spawn_enemy. Spawns a test enemy.",
		_spawn_enemy_from_console
	)
	DeveloperConsole.register_command(
		&"clear_enemies",
		"Usage: clear_enemies. Removes all active enemies.",
		_clear_enemies_from_console
	)
	DeveloperConsole.register_command(
		&"spawn_health",
		"Usage: spawn_health <amount>.",
		_spawn_health_from_console
	)
	DeveloperConsole.register_command(
		&"spawn_ammo",
		"Usage: spawn_ammo <amount>.",
		_spawn_ammo_from_console
	)
	DeveloperConsole.register_command(
		&"spawn_weapon",
		"Usage: spawn_weapon pistol.",
		_spawn_weapon_from_console
	)
	DeveloperConsole.register_command(
		&"give_weapon",
		"Usage: give_weapon pistol.",
		_give_weapon_from_console
	)
	DeveloperConsole.register_command(
		&"drop_weapon",
		"Usage: drop_weapon.",
		_drop_weapon_from_console
	)
	DeveloperConsole.register_command(
		&"give_organ",
		"Usage: give_organ <organ_id>. Available: heart, leg_lump, spring_bladder.",
		_give_organ_from_console
	)


func _unregister_debug_commands() -> void:
	DeveloperConsole.unregister_command(
		&"damage_player",
		_damage_player_from_console
	)
	DeveloperConsole.unregister_command(
		&"heal_player",
		_heal_player_from_console
	)
	DeveloperConsole.unregister_command(
		&"kill_player",
		_kill_player_from_console
	)
	DeveloperConsole.unregister_command(
		&"respawn_player",
		_respawn_player_from_console
	)
	DeveloperConsole.unregister_command(
		&"spawn_enemy",
		_spawn_enemy_from_console
	)
	DeveloperConsole.unregister_command(
		&"clear_enemies",
		_clear_enemies_from_console
	)
	DeveloperConsole.unregister_command(
		&"spawn_health",
		_spawn_health_from_console
	)
	DeveloperConsole.unregister_command(
		&"spawn_ammo",
		_spawn_ammo_from_console
	)
	DeveloperConsole.unregister_command(
		&"spawn_weapon",
		_spawn_weapon_from_console
	)
	DeveloperConsole.unregister_command(
		&"give_weapon",
		_give_weapon_from_console
	)
	DeveloperConsole.unregister_command(
		&"drop_weapon",
		_drop_weapon_from_console
	)
	DeveloperConsole.unregister_command(
		&"give_organ",
		_give_organ_from_console
	)


func _spawn_player() -> CharacterBody3D:
	var player: CharacterBody3D = PLAYER_SCENE.instantiate() as CharacterBody3D

	assert(player != null, "Player scene root must inherit CharacterBody3D.")

	_gameplay_root.add_child(player)
	player.global_position = player_spawn_position

	return player


func _setup_player_debug(player: CharacterBody3D) -> void:
	DebugStatsOverlay.setup(player)

	var weapon_controller: WeaponController = (
		player.get_node_or_null("WeaponController")
		as WeaponController
	)

	assert(
		weapon_controller != null,
		"Player requires a WeaponController."
	)

	weapon_controller.weapon_dropped.connect(
		_on_weapon_dropped
	)
	weapon_controller.weapon_replaced.connect(
		_on_weapon_replaced
	)


func _damage_player_from_console(arguments: PackedStringArray) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error("Usage: damage_player <amount>.")
		return

	var amount: float = _parse_positive_amount(arguments[0], "Damage amount")

	if amount <= 0.0:
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	player.apply_debug_damage(amount)
	DeveloperConsole.log_info(
		"Applied %.1f debug damage to player."
		% amount
	)


func _heal_player_from_console(arguments: PackedStringArray) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error("Usage: heal_player <amount|full>.")
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var value: String = arguments[0].to_lower()

	if value == "full":
		player.restore_full_debug_health()
		DeveloperConsole.log_info("Restored player health to full.")
		return

	var amount: float = _parse_positive_amount(value, "Heal amount")

	if amount <= 0.0:
		return

	var restored_health: float = player.restore_debug_health(amount)

	DeveloperConsole.log_info(
		"Restored %.1f player health."
		% restored_health
	)


func _kill_player_from_console(arguments: PackedStringArray) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: kill_player.")
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	player.kill_for_debug()
	DeveloperConsole.log_info("Killed player with debug damage.")


func _respawn_player_from_console(arguments: PackedStringArray) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: respawn_player.")
		return

	_clear_active_enemies()

	if is_instance_valid(_player):
		_player.queue_free()

	_player = _spawn_player()
	_world_pickup_spawner.setup(_player)
	_setup_player_debug(_player)
	player_ready.emit(_player)

	DeveloperConsole.log_info(
		"Respawned player at %.1f, %.1f, %.1f."
		% [
			_player.global_position.x,
			_player.global_position.y,
			_player.global_position.z,
		]
	)
	


func _spawn_enemy_from_console(arguments: PackedStringArray) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: spawn_enemy.")
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var enemy: Enemy = _spawn_enemy(player)

	DeveloperConsole.log_info(
		"Spawned %s at %.1f, %.1f, %.1f."
		% [
			enemy.definition.display_name,
			enemy.global_position.x,
			enemy.global_position.y,
			enemy.global_position.z,
		]
	)


func _clear_enemies_from_console(arguments: PackedStringArray) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: clear_enemies.")
		return

	var removed_count: int = _active_enemies.size()

	_clear_active_enemies()

	DeveloperConsole.log_info(
		"Cleared %d enemies."
		% removed_count
	)


func _spawn_enemy(target_player: CharacterBody3D) -> Enemy:
	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy

	assert(enemy != null, "Enemy scene root must inherit CharacterBody3D.")

	_gameplay_root.add_child(enemy)
	enemy.global_position = enemy_spawn_position

	var target_damageable: Damageable = (
		target_player.get_node_or_null("HealthComponent") as Damageable
	)
	assert(target_damageable != null, "Player requires a HealthComponent.")

	enemy.setup_target(target_player, target_damageable)
	enemy.enemy_died.connect(_on_enemy_died)

	_active_enemies.append(enemy)

	return enemy


func _clear_active_enemies() -> void:
	for enemy: Enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

	_active_enemies.clear()


func _spawn_health_from_console(arguments: PackedStringArray) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error("Usage: spawn_health <amount>.")
		return

	var amount: float = _parse_positive_amount(
		arguments[0],
		"Health amount"
	)

	if amount <= 0.0:
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var spawn_position: Vector3 = (
		player.global_position
		+ player.global_transform.basis.z * -2.0
		+ Vector3.UP * 2.0
	)

	var pickup: WorldPickup = _spawn_pickup(
		HealthPickupPayload.new(
			health_pickup_definition,
			amount
		),
		spawn_position,
		player
	)

	DeveloperConsole.log_info(
		"Spawned health pickup for %.1f HP at %.1f, %.1f, %.1f."
		% [
			amount,
			pickup.global_position.x,
			pickup.global_position.y,
			pickup.global_position.z,
		]
	)
	

func _spawn_ammo_from_console(
	arguments: PackedStringArray
) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error(
			"Usage: spawn_ammo <amount>."
		)
		return

	if not arguments[0].is_valid_int():
		DeveloperConsole.log_error(
			"Ammo amount must be a whole number."
		)
		return

	var amount: int = arguments[0].to_int()

	if amount <= 0:
		DeveloperConsole.log_error(
			"Ammo amount must be greater than zero."
		)
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var spawn_position: Vector3 = (
		player.global_position
		+ player.global_transform.basis.z * -2.0
		+ Vector3.UP * 2.0
	)

	var pickup: WorldPickup = _spawn_pickup(
		AmmoPickupPayload.new(
			universal_ammo_definition,
			amount
		),
		spawn_position,
		player
	)

	DeveloperConsole.log_info(
		"Spawned %d ammo at %.1f, %.1f, %.1f."
		% [
			amount,
			pickup.global_position.x,
			pickup.global_position.y,
			pickup.global_position.z,
		]
	)
	
	
func _spawn_weapon_from_console(
	arguments: PackedStringArray
) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error("Usage: spawn_weapon pistol.")
		return

	var weapon_definition: WeaponDefinition = (
		_get_weapon_definition_from_argument(arguments[0])
	)

	if weapon_definition == null:
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var spawn_position: Vector3 = (
		player.global_position
		+ player.global_transform.basis.z * -2.0
		+ Vector3.UP * 2.0
	)

	var weapon: WeaponInstance = WeaponInstance.new(
		weapon_definition
	)

	var pickup: WorldPickup = _spawn_pickup(
		WeaponPickupPayload.new(weapon),
		spawn_position,
		player
	)

	DeveloperConsole.log_info(
		"Spawned %s at %.1f, %.1f, %.1f."
		% [
			weapon_definition.display_name,
			pickup.global_position.x,
			pickup.global_position.y,
			pickup.global_position.z,
		]
	)


func _give_weapon_from_console(
	arguments: PackedStringArray
) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error("Usage: give_weapon pistol.")
		return

	var weapon_definition: WeaponDefinition = (
		_get_weapon_definition_from_argument(arguments[0])
	)

	if weapon_definition == null:
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var weapon_controller: WeaponController = (
		player.get_node_or_null("WeaponController")
		as WeaponController
	)

	if weapon_controller == null:
		DeveloperConsole.log_error("Player WeaponController is unavailable.")
		return

	var weapon: WeaponInstance = WeaponInstance.new(
		weapon_definition
	)

	if not weapon_controller.try_accept_weapon(weapon):
		DeveloperConsole.log_warning(
			"Cannot add %s. Select a regular weapon to replace it."
			% weapon_definition.display_name
		)
		return

	DeveloperConsole.log_info(
		"Gave player %s."
		% weapon_definition.display_name
	)


func _drop_weapon_from_console(
	arguments: PackedStringArray
) -> void:
	if not arguments.is_empty():
		DeveloperConsole.log_error("Usage: drop_weapon.")
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var weapon_controller: WeaponController = (
		player.get_node_or_null("WeaponController")
		as WeaponController
	)

	if weapon_controller == null:
		DeveloperConsole.log_error("Player WeaponController is unavailable.")
		return

	if not weapon_controller.try_drop_active_regular_weapon():
		DeveloperConsole.log_warning(
			"Cannot drop FingerGun or an empty slot."
		)
		return

	DeveloperConsole.log_info("Dropped active weapon.")
	

func _spawn_pickup(
	payload: PickupPayload,
	spawn_position: Vector3,
	_player: Node3D
) -> WorldPickup:
	return _world_pickup_spawner.spawn(
		payload,
		spawn_position
	)
	

func _give_organ_from_console(
	arguments: PackedStringArray
) -> void:
	if arguments.size() != 1:
		DeveloperConsole.log_error(
			"Usage: give_organ health|speed|jump."
		)
		return

	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var organ_inventory: OrganInventoryComponent = (
		player.get_node_or_null("OrganInventoryComponent")
		as OrganInventoryComponent
	)

	if organ_inventory == null:
		DeveloperConsole.log_error(
			"Player OrganInventoryComponent is unavailable."
		)
		return

	var organ_definition: OrganDefinition = (
		_get_organ_definition_from_argument(arguments[0])
	)

	if organ_definition == null:
		return

	var grid_position: Vector2i = (
		_get_debug_organ_grid_position(
			organ_definition.organ_id
		)
	)

	var organ: OrganInstance = OrganInstance.new(
		organ_definition,
		ItemRarity.Type.COMMON
	)

	if not organ_inventory.try_install_organ(
		organ,
		grid_position
	):
		DeveloperConsole.log_warning(
			"Cannot install %s at %d, %d."
			% [
				organ_definition.display_name,
				grid_position.x,
				grid_position.y,
			]
		)
		return

	DeveloperConsole.log_info(
		"Installed debug organ: %s."
		% organ_definition.display_name
	)


func _get_organ_definition_from_argument(
	argument: String
) -> OrganDefinition:
	var organ_id: StringName = StringName(
		argument.to_lower()
	)

	var available_definitions: Array[OrganDefinition] = [
		max_health_organ_definition,
		move_speed_organ_definition,
		jump_height_organ_definition,
	]

	for organ_definition: OrganDefinition in available_definitions:
		if organ_definition == null:
			continue

		if organ_definition.organ_id == organ_id:
			return organ_definition

	DeveloperConsole.log_error(
		"Unknown organ ID '%s'. Available: heart, leg_lump, spring_bladder."
		% argument
	)
	return null


func _get_debug_organ_grid_position(
	organ_id: StringName
) -> Vector2i:
	match organ_id:
		&"heart":
			return Vector2i(0, 0)

		&"leg_lump":
			return Vector2i(1, 0)

		&"spring_bladder":
			return Vector2i(0, 2)

		_:
			return Vector2i(0, 0)


func _on_weapon_dropped(weapon: WeaponInstance) -> void:
	var pickup: WorldPickup = (
		_world_pickup_spawner.spawn_dropped_weapon(weapon)
	)

	if pickup == null:
		push_error("Failed to spawn dropped weapon pickup.")


func _on_weapon_replaced(
	replaced_weapon: WeaponInstance,
	_new_weapon: WeaponInstance
) -> void:
	var pickup: WorldPickup = (
		_world_pickup_spawner.spawn_dropped_weapon(replaced_weapon)
	)

	if pickup == null:
		push_error("Failed to spawn replaced weapon pickup.")
		

func _spawn_weapon_pickup_near_player(
	weapon: WeaponInstance
) -> void:
	var player: CharacterBody3D = _get_valid_player()

	if player == null:
		return

	var spawn_position: Vector3 = (
		player.global_position
		+ player.global_transform.basis.z * -2.0
		+ Vector3.UP * 1.0
	)

	_spawn_pickup(
		WeaponPickupPayload.new(weapon),
		spawn_position,
		player
	)
	
	
func _on_enemy_died(
	enemy: CharacterBody3D,
	_damage_info: DamageInfo
) -> void:
	var typed_enemy: Enemy = enemy as Enemy

	if typed_enemy == null:
		return

	_active_enemies.erase(typed_enemy)


func _get_valid_player() -> CharacterBody3D:
	if is_instance_valid(_player):
		return _player

	DeveloperConsole.log_error("Player is unavailable.")
	return null


func _get_weapon_definition_from_argument(
	argument: String
) -> WeaponDefinition:
	var weapon_id: StringName = StringName(
		argument.to_lower()
	)

	match weapon_id:
		&"pistol":
			return pistol_definition
		_:
			DeveloperConsole.log_error(
				"Unknown weapon '%s'. Available: pistol."
				% argument
			)
			return null
			

func _parse_positive_amount(value: String, label: String) -> float:
	if not value.is_valid_float():
		DeveloperConsole.log_error("%s must be a number." % label)
		return 0.0

	var amount: float = value.to_float()

	if amount <= 0.0:
		DeveloperConsole.log_error("%s must be greater than zero." % label)
		return 0.0

	return amount


func get_player() -> CharacterBody3D:
	if is_instance_valid(_player):
		return _player

	return null


func get_world_pickup_spawner() -> WorldPickupSpawner:
	return _world_pickup_spawner


func _validate_organ_definition(
	organ_definition: OrganDefinition,
	export_name: String
) -> void:
	assert(
		organ_definition != null,
		"GameRoot requires %s." % export_name
	)
	assert(
		organ_definition.is_valid(),
		"Invalid OrganDefinition '%s': %s"
		% [
			organ_definition.resource_path,
			organ_definition.get_validation_error(),
		]
	)
