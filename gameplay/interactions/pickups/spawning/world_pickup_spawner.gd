class_name WorldPickupSpawner
extends Node

signal pickup_spawned(pickup: WorldPickup)

const WORLD_PICKUP_SCENE: PackedScene = preload(
	"res://gameplay/interactions/pickups/world_pickup.tscn"
)

@export_category("Spawn Motion")
@export_range(0.0, 30.0, 0.01, "suffix:m/s")
var drop_forward_speed_mps: float = 3.5

@export_range(0.0, 30.0, 0.01, "suffix:m/s")
var drop_upward_speed_mps: float = 1.5

@export_range(0.0, 30.0, 0.01, "suffix:m/s")
var drop_side_speed_mps: float = 0.65

@export_range(0.0, 10.0, 0.01, "suffix:s")
var pickup_lockout_duration_s: float = 0.4

@export_category("Dependencies")
@export var gameplay_root: Node

var _player: CharacterBody3D


func setup(player: CharacterBody3D) -> void:
	assert(player != null, "WorldPickupSpawner requires a player.")
	assert(
		gameplay_root != null,
		"WorldPickupSpawner requires a gameplay_root."
	)

	_player = player


func spawn(
	payload: PickupPayload,
	spawn_position: Vector3
) -> WorldPickup:
	if payload == null:
		return null

	if not is_instance_valid(_player):
		return null

	var pickup: WorldPickup = (
		WORLD_PICKUP_SCENE.instantiate() as WorldPickup
	)

	if pickup == null:
		push_error("WorldPickup scene root must be WorldPickup.")
		return null

	gameplay_root.add_child(pickup)
	pickup.global_position = spawn_position
	pickup.setup(payload, _player)

	pickup_spawned.emit(pickup)

	return pickup


func spawn_dropped_weapon(
	weapon: WeaponInstance
) -> WorldPickup:
	if weapon == null or not is_instance_valid(_player):
		return null

	var anchor: Node3D = _get_pickup_anchor()

	if anchor == null:
		return null

	var payload: WeaponPickupPayload = (
		WeaponPickupPayload.new(weapon)
	)

	var pickup: WorldPickup = spawn(
		payload,
		anchor.global_position
	)

	if pickup == null:
		return null

	pickup.launch_from(
		anchor.global_position,
		_get_drop_velocity(anchor)
	)
	pickup.set_interaction_lockout(
		pickup_lockout_duration_s
	)

	return pickup


func _get_pickup_anchor() -> Node3D:
	var anchor: Node3D = (
		_player.get_node_or_null(
			"PickupPresentationAnchor"
		) as Node3D
	)

	if anchor == null:
		push_error(
			"Player requires a PickupPresentationAnchor Node3D."
		)

	return anchor


func _get_drop_velocity(anchor: Node3D) -> Vector3:
	var side_direction: float = randf_range(-1.0, 1.0)

	return (
		-anchor.global_transform.basis.z
		* drop_forward_speed_mps
		+ Vector3.UP * drop_upward_speed_mps
		+ anchor.global_transform.basis.x
		* side_direction
		* drop_side_speed_mps
	)
