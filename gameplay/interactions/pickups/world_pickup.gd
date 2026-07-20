class_name WorldPickup
extends Node3D

const RARITY_CATALOG: RarityCatalog = preload(
	"res://data/items/rarity_catalog.tres"
)

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

@export_category("Outline")
@export_range(0.0, 1.0, 0.01)
var distant_outline_alpha: float = 0.22

@export_range(0.0, 1.0, 0.01)
var distant_outline_saturation: float = 0.35

@export_range(0.0, 1.0, 0.01)
var near_outline_alpha: float = 0.6

@export_range(0.0, 1.0, 0.01)
var near_outline_saturation: float = 0.7

@export_range(0.0, 1.0, 0.01)
var aimed_outline_alpha: float = 1.0

@export_range(0.0, 1.0, 0.01)
var aimed_outline_saturation: float = 1.0

@export_range(
	0.0,
	20.0,
	0.01,
	"suffix:Hz"
) var outline_pulse_frequency_hz: float = 1.8

@export_range(0.0, 1.0, 0.01)
var outline_pulse_alpha_strength: float = 0.22

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

var _outline_material: ShaderMaterial
var _is_player_near: bool = false
var _is_aimed: bool = false

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

	_visual.frame_changed.connect(
		_on_visual_frame_changed
	)

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

	var collection_target: Node3D = _get_collection_target(
		receiver
	)

	if collection_target == null:
		return false

	var apply_result: PickupApplyResult = (
		_payload.try_apply_to(receiver)
	)

	if apply_result == null:
		return false

	match apply_result.status:
		PickupApplyResult.Status.REJECTED:
			return false

		PickupApplyResult.Status.PARTIALLY_CONSUMED:
			return apply_result.accepted_amount > 0

		PickupApplyResult.Status.CONSUMED:
			_begin_collection(collection_target)
			return true

	return false


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


func set_is_player_near(value: bool) -> void:
	if _is_player_near == value:
		return

	_is_player_near = value
	_apply_outline_state()


func set_is_aimed(value: bool) -> void:
	if _is_aimed == value:
		return

	_is_aimed = value
	_apply_outline_state()


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

	_setup_outline_material()
	_update_outline_sprite_texture()
	_apply_outline_state()


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
	_update_outline_state()


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

	var eased_progress: float = ease(
		progress,
		-3.0
	)

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

	if _outline_material != null:
		_outline_material.set_shader_parameter(
			"line_color",
			Color.TRANSPARENT
		)

	_interaction_area.set_deferred(
		"monitoring",
		false
	)

	_interaction_area.set_deferred(
		"monitorable",
		false
	)

	collection_started.emit(self, _payload)


func _setup_outline_material() -> void:
	if _outline_material != null:
		return

	var template_material: ShaderMaterial = (
		_visual.material_override as ShaderMaterial
	)

	if template_material == null:
		push_error(
			"WorldPickup Visual requires a ShaderMaterial "
			+ "in material_override."
		)
		return

	_outline_material = (
		template_material.duplicate() as ShaderMaterial
	)

	_visual.material_override = _outline_material


func _update_outline_sprite_texture() -> void:
	if _outline_material == null:
		return

	if _visual.sprite_frames == null:
		return

	if not _visual.sprite_frames.has_animation(
		_visual.animation
	):
		return

	var frame_texture: Texture2D = (
		_visual.sprite_frames.get_frame_texture(
			_visual.animation,
			_visual.frame
		)
	)

	if frame_texture == null:
		return

	_outline_material.set_shader_parameter(
		"sprite_texture",
		frame_texture
	)


func _on_visual_frame_changed() -> void:
	_update_outline_sprite_texture()


func _apply_outline_state() -> void:
	if _outline_material == null or _payload == null:
		return

	if _state == State.COLLECTING:
		return

	var rarity_definition: RarityDefinition = (
		RARITY_CATALOG.get_definition(_payload.get_rarity())
	)

	if rarity_definition == null:
		return

	var outline_color: Color = rarity_definition.outline_color
	var outline_alpha: float = distant_outline_alpha
	var saturation: float = distant_outline_saturation

	if _is_player_near:
		outline_alpha = near_outline_alpha
		saturation = near_outline_saturation

	if _is_aimed:
		outline_alpha = aimed_outline_alpha
		saturation = aimed_outline_saturation

	var luminance: float = outline_color.get_luminance()

	var grayscale: Color = Color(
		luminance,
		luminance,
		luminance,
		1.0
	)

	var state_color: Color = grayscale.lerp(
		outline_color,
		saturation
	)

	if not _is_aimed:
		var pulse: float = 1.0 + (
			sin(
				_hover_time_s
				* TAU
				* outline_pulse_frequency_hz
			)
			* outline_pulse_alpha_strength
		)

		outline_alpha *= pulse

	state_color.a = clampf(
		outline_alpha,
		0.0,
		1.0
	)

	_outline_material.set_shader_parameter(
		"line_color",
		state_color
	)

	_outline_material.set_shader_parameter(
		"glowSize",
		rarity_definition.glow_size_px
	)


func _update_outline_state() -> void:
	if _state != State.IDLE:
		return

	_apply_outline_state()


func _unlock_interaction_after_delay(
	duration_s: float
) -> void:
	await get_tree().create_timer(duration_s).timeout

	if not is_instance_valid(self):
		return

	_is_interaction_locked = false
