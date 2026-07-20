class_name WorldPickup
extends Node3D

@export_category("Ground Placement")
@export_flags_3d_physics var ground_collision_mask: int = 129

@export_range(
	0.01,
	1000.0,
	0.01,
	"suffix:m"
) var ground_search_distance_m: float = 100.0

@export_range(
	0.01,
	100.0,
	0.01,
	"suffix:m/s"
) var descent_speed_mps: float = 8.0

@export_category("Presentation")
@export_range(
	0.0,
	10.0,
	0.01,
	"suffix:m"
) var hover_height_m: float = 0.16

@export_range(
	0.0,
	10.0,
	0.01,
	"suffix:m"
) var hover_amplitude_m: float = 0.05

@export_range(
	0.0,
	20.0,
	0.01,
	"suffix:Hz"
) var hover_frequency_hz: float = 1.5

@export_range(
	0.0,
	30.0,
	0.01,
	"suffix:rad/s"
) var face_turn_speed: float = 10.0

@onready var _interaction_area: PickupInteractionArea = $InteractionArea
@onready var _visual_root: Node3D = $VisualRoot
@onready var _visual: AnimatedSprite3D = $VisualRoot/Visual

var _payload: PickupPayload
var _player: Node3D
var _is_collected: bool = false
var _has_reached_ground: bool = false
var _hover_time_s: float = 0.0
var _visual_rest_position: Vector3


func _ready() -> void:
	assert(
		ground_collision_mask != 0,
		"WorldPickup requires a non-empty ground collision mask."
	)

	_visual_rest_position = _visual_root.position
	_apply_presentation()


func _physics_process(delta: float) -> void:
	_update_facing(delta)

	if not _has_reached_ground:
		_update_ground_descent(delta)
		return

	_hover_time_s += delta
	_update_hover()


func setup(
	payload: PickupPayload,
	player: Node3D
) -> void:
	assert(payload != null, "WorldPickup requires a PickupPayload.")
	assert(
		payload.get_presentation() != null,
		"WorldPickup payload requires a PickupPresentationDefinition."
	)
	assert(player != null, "WorldPickup requires a player reference.")

	_payload = payload
	_player = player

	if is_node_ready():
		_apply_presentation()


func try_interact(receiver: Node) -> bool:
	if _is_collected or _payload == null:
		return false

	if not _payload.try_apply_to(receiver):
		return false

	_is_collected = true
	queue_free()

	return true


func is_auto_interaction_enabled() -> bool:
	if _payload == null:
		return false

	var presentation: PickupPresentationDefinition = (
		_payload.get_presentation()
	)

	return presentation.is_auto_pickup_enabled


func get_display_name() -> String:
	if _payload == null:
		return "Unconfigured pickup"

	return _payload.get_display_name()


func _apply_presentation() -> void:
	if _payload == null:
		return

	var presentation: PickupPresentationDefinition = (
		_payload.get_presentation()
	)

	if presentation == null:
		return

	_visual.sprite_frames = presentation.sprite_frames
	_visual.animation = presentation.animation_name
	_visual.position = presentation.visual_offset
	_visual.scale = presentation.visual_scale
	_visual.play()


func _update_ground_descent(delta: float) -> void:
	var ground_y: float = _find_ground_y()

	if is_nan(ground_y):
		return

	if global_position.y <= ground_y + 0.01:
		global_position.y = maxf(
			global_position.y,
			ground_y
		)
		_has_reached_ground = true
		_hover_time_s = 0.0
		return

	global_position.y = move_toward(
		global_position.y,
		ground_y,
		descent_speed_mps * delta
	)


func _find_ground_y() -> float:
	var ray_origin: Vector3 = global_position + Vector3.UP * 0.01
	var ray_end: Vector3 = ray_origin + (
		Vector3.DOWN * ground_search_distance_m
	)

	var query: PhysicsRayQueryParameters3D = (
		PhysicsRayQueryParameters3D.create(
			ray_origin,
			ray_end,
			ground_collision_mask
		)
	)

	var result: Dictionary = (
		get_world_3d()
		.direct_space_state
		.intersect_ray(query)
	)

	if result.is_empty():
		return NAN

	var hit_position: Vector3 = result["position"]

	return hit_position.y


func _update_hover() -> void:
	var hover_offset_y: float = hover_height_m + (
		sin(_hover_time_s * TAU * hover_frequency_hz)
		* hover_amplitude_m
	)

	_visual_root.position = (
		_visual_rest_position
		+ Vector3.UP * hover_offset_y
	)


func _update_facing(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	var flat_direction: Vector3 = (
		_player.global_position - _visual_root.global_position
	)
	flat_direction.y = 0.0

	if flat_direction.length_squared() <= 0.0001:
		return

	var target_rotation_y: float = atan2(
		-flat_direction.x,
		-flat_direction.z
	)

	_visual_root.rotation.y = lerp_angle(
		_visual_root.rotation.y,
		target_rotation_y,
		face_turn_speed * delta
	)
