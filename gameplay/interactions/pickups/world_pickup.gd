class_name WorldPickup
extends Node3D

signal collection_started(
	pickup: WorldPickup,
	payload: PickupPayload
)

signal collection_finished(
	pickup: WorldPickup,
	payload: PickupPayload
)

enum State {
	GROUNDING,
	IDLE,
	COLLECTING,
}

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

@export_range(
	0.0,
	100.0,
	0.01,
	"suffix:m/s²"
) var drop_gravity_mps2: float = 18.0

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
	0.01,
	1.0,
	0.01,
	"suffix:s"
) var hover_enter_duration_s: float = 0.12

@export_range(
	0.0,
	30.0,
	0.01,
	"suffix:1/s"
) var face_lerp_speed: float = 12.0

@export_category("Collection")
@export_range(
	0.01,
	3.0,
	0.01,
	"suffix:s"
) var collect_duration_s: float = 0.18

@export_range(
	0.0,
	10.0,
	0.01,
	"suffix:m"
) var collect_arc_height_m: float = 0.25

@onready var _interaction_area: PickupInteractionArea = $InteractionArea
@onready var _visual_root: Node3D = $VisualRoot
@onready var _visual: AnimatedSprite3D = $VisualRoot/Visual

var _payload: PickupPayload
var _player: Node3D
var _state: State = State.GROUNDING

var _has_reached_ground: bool = false
var _is_interaction_locked: bool = false

var _hover_time_s: float = 0.0
var _hover_enter_elapsed_s: float = 0.0
var _visual_rest_position: Vector3

var _launch_velocity: Vector3 = Vector3.ZERO
var _has_launch_velocity: bool = false

var _collection_target: Node3D
var _collection_start_position: Vector3
var _collection_elapsed_s: float = 0.0


func _ready() -> void:
	assert(
		ground_collision_mask != 0,
		"WorldPickup requires a non-empty ground collision mask."
	)

	_visual_rest_position = _visual_root.position
	_apply_presentation()


func _physics_process(delta: float) -> void:
	match _state:
		State.GROUNDING:
			_update_grounding(delta)

		State.IDLE:
			_update_idle(delta)

		State.COLLECTING:
			_update_collection(delta)


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


func launch_from(
	origin: Vector3,
	initial_velocity: Vector3
) -> void:
	global_position = origin
	_launch_velocity = initial_velocity
	_has_launch_velocity = true
	_has_reached_ground = false
	_state = State.GROUNDING


func set_interaction_lockout(duration_s: float) -> void:
	if duration_s <= 0.0:
		return

	_is_interaction_locked = true
	_unlock_interaction_after_delay(duration_s)


func try_interact(receiver: Node) -> bool:
	if _state == State.COLLECTING:
		return false

	if _is_interaction_locked:
		return false

	if _payload == null:
		return false

	if not _payload.try_apply_to(receiver):
		return false

	var collection_target: Node3D = _get_collection_target(receiver)

	if collection_target == null:
		return false

	_begin_collection(collection_target)

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


func _update_grounding(delta: float) -> void:
	_update_facing(delta)

	if _has_launch_velocity:
		var ground_y: float = _find_ground_y()

		_launch_velocity.y -= drop_gravity_mps2 * delta

		var previous_position: Vector3 = global_position
		var next_position: Vector3 = (
			previous_position
			+ _launch_velocity * delta
		)

		if not is_nan(ground_y):
			var crosses_ground: bool = (
				previous_position.y >= ground_y
				and next_position.y <= ground_y
			)

			if crosses_ground:
				global_position = Vector3(
					next_position.x,
					ground_y,
					next_position.z
				)
				_finish_grounding()
				return

		global_position = next_position
		return

	var target_ground_y: float = _find_ground_y()

	if is_nan(target_ground_y):
		return

	if global_position.y <= target_ground_y + 0.01:
		global_position.y = maxf(
			global_position.y,
			target_ground_y
		)
		_finish_grounding()
		return

	global_position.y = move_toward(
		global_position.y,
		target_ground_y,
		descent_speed_mps * delta
	)


func _finish_grounding() -> void:
	_has_launch_velocity = false
	_has_reached_ground = true
	_state = State.IDLE
	_hover_time_s = 0.0
	_hover_enter_elapsed_s = 0.0
	

func _update_idle(delta: float) -> void:
	_hover_time_s += delta
	_hover_enter_elapsed_s += delta

	var hover_enter_progress: float = clampf(
		_hover_enter_elapsed_s / hover_enter_duration_s,
		0.0,
		1.0
	)
	var hover_weight: float = ease(
		hover_enter_progress,
		-2.0
	)

	_update_hover(hover_weight)
	_update_facing(delta)


func _update_collection(delta: float) -> void:
	if not is_instance_valid(_collection_target):
		queue_free()
		return

	_collection_elapsed_s += delta

	var progress: float = clampf(
		_collection_elapsed_s / collect_duration_s,
		0.0,
		1.0
	)
	var eased_progress: float = ease(progress, -3.0)

	var target_position: Vector3 = (
		_collection_target.global_position
	)

	var arc_offset: Vector3 = Vector3.UP * (
		sin(progress * PI) * collect_arc_height_m
	)

	global_position = _collection_start_position.lerp(
		target_position,
		eased_progress
	) + arc_offset

	_update_facing(delta)

	if progress < 1.0:
		return

	collection_finished.emit(self, _payload)
	queue_free()


func _update_hover(weight: float) -> void:
	var hover_offset_y: float = hover_height_m + (
		sin(_hover_time_s * TAU * hover_frequency_hz)
		* hover_amplitude_m
	)

	_visual_root.position = _visual_rest_position + (
		Vector3.UP
		* hover_offset_y
		* weight
	)


func _update_facing(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	var target_position: Vector3 = _player.global_position

	if _visual_root.global_position.distance_squared_to(
		target_position
	) <= 0.0001:
		return

	var target_transform: Transform3D = (
		_visual_root.global_transform.looking_at(
			target_position,
			Vector3.UP,
			true
		)
	)

	_visual_root.global_transform = (
		_visual_root.global_transform.interpolate_with(
			target_transform,
			clampf(face_lerp_speed * delta, 0.0, 1.0)
		)
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

	if is_instance_valid(_player):
		query.exclude = [_player.get_rid()]

	var result: Dictionary = (
		get_world_3d()
		.direct_space_state
		.intersect_ray(query)
	)

	if result.is_empty():
		return NAN

	var hit_position: Vector3 = result["position"]

	return hit_position.y


func _get_collection_target(receiver: Node) -> Node3D:
	var player: CharacterBody3D = receiver as CharacterBody3D

	if player == null:
		return null

	var anchor: Node3D = (
		player.get_node_or_null(
			"PickupPresentationAnchor"
		) as Node3D
	)

	if anchor != null:
		return anchor

	return player


func _begin_collection(target: Node3D) -> void:
	_state = State.COLLECTING
	_collection_target = target
	_collection_start_position = global_position
	_collection_elapsed_s = 0.0

	_interaction_area.set_deferred(
		"monitoring",
		false
	)
	_interaction_area.set_deferred(
		"monitorable",
		false
	)

	collection_started.emit(self, _payload)


func _unlock_interaction_after_delay(
	duration_s: float
) -> void:
	await get_tree().create_timer(duration_s).timeout

	if not is_instance_valid(self):
		return

	_is_interaction_locked = false
