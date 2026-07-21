class_name DamageDirectionIndicator
extends Control

@export_category("Visual")
@export var indicator_texture: Texture2D
@export var color: Color = Color(1.0, 0.08, 0.08, 0.9)
@export_range(0.0, 1000.0, 1.0, "suffix:px")
var distance_from_center_px: float = 130.0

@export_range(0.0, 1.0, 0.001, "suffix:s")
var hold_duration_s: float = 0.06

@export_range(0.1, 100.0, 0.1, "suffix:1/s")
var fade_out_speed: float = 8.0

@export_range(0.0, 1.0, 0.01)
var minimum_damage_ratio: float = 0.02

@export_range(0.0, 1.0, 0.01)
var maximum_damage_ratio: float = 0.35

@export_range(0.0, 2.0, 0.01)
var max_scale: float = 1.25

@onready var _indicator: TextureRect = $Indicator

var _player: CharacterBody3D
var _camera: Camera3D
var _health_component: HealthComponent

var _hold_remaining_s: float = 0.0
var _target_alpha: float = 0.0
var _current_alpha: float = 0.0
var _target_scale: float = 1.0
var _current_scale: float = 1.0


func _ready() -> void:
	assert(
		_indicator != null,
		"DamageDirectionIndicator requires an Indicator TextureRect."
	)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_indicator.texture = indicator_texture
	_indicator.modulate = Color(
		color.r,
		color.g,
		color.b,
		0.0
	)


func setup(player: CharacterBody3D) -> void:
	if player == null:
		push_error("DamageDirectionIndicator requires a player.")
		return

	var camera: Camera3D = (
		player.get_node_or_null(
			"CameraPivot/CameraJuiceOffset/Camera3D"
		) as Camera3D
	)
	var health_component: HealthComponent = (
		player.get_node_or_null("HealthComponent")
		as HealthComponent
	)

	if camera == null:
		push_error(
			"DamageDirectionIndicator requires Player/CameraPivot/"
			+ "CameraJuiceOffset/Camera3D."
		)
		return

	if health_component == null:
		push_error(
			"DamageDirectionIndicator requires Player/HealthComponent."
		)
		return

	_disconnect_health_signal()

	_player = player
	_camera = camera
	_health_component = health_component

	_health_component.damaged.connect(_on_player_damaged)


func _process(delta: float) -> void:
	if _hold_remaining_s > 0.0:
		_hold_remaining_s = maxf(
			_hold_remaining_s - delta,
			0.0
		)
	else:
		_target_alpha = 0.0
		_target_scale = 1.0

	var fade_weight: float = _get_smoothing_weight(
		fade_out_speed,
		delta
	)

	_current_alpha = lerpf(
		_current_alpha,
		_target_alpha,
		fade_weight
	)
	_current_scale = lerpf(
		_current_scale,
		_target_scale,
		fade_weight
	)

	_indicator.modulate = Color(
		color.r,
		color.g,
		color.b,
		_current_alpha
	)
	_indicator.scale = Vector2.ONE * _current_scale


func _on_player_damaged(
	damage_info: DamageInfo,
	applied_damage: float
) -> void:
	if damage_info == null or applied_damage <= 0.0:
		return

	if _player == null or _camera == null:
		return

	var max_health: float = _health_component.get_max_health()

	if max_health <= 0.0:
		return

	var damage_ratio: float = clampf(
		applied_damage / max_health,
		0.0,
		1.0
	)

	if damage_ratio < minimum_damage_ratio:
		return

	var world_direction: Vector3 = _get_source_direction(
		damage_info
	)
	var local_direction: Vector3 = (
		_camera.global_transform.basis.inverse()
		* world_direction
	)
	local_direction.y = 0.0

	if local_direction.length_squared() <= 0.0001:
		return

	local_direction = local_direction.normalized()

	var angle_rad: float = atan2(
		local_direction.x,
		-local_direction.z
	)

	var center: Vector2 = size * 0.5
	var radial_offset: Vector2 = Vector2(
		sin(angle_rad),
		-cos(angle_rad)
	) * distance_from_center_px

	_indicator.position = (
		center
		+ radial_offset
		- _indicator.size * 0.5
	)
	_indicator.rotation = angle_rad

	var intensity: float = inverse_lerp(
		minimum_damage_ratio,
		maximum_damage_ratio,
		damage_ratio
	)
	intensity = clampf(intensity, 0.0, 1.0)

	_target_alpha = lerpf(0.35, color.a, intensity)
	_current_alpha = maxf(
		_current_alpha,
		_target_alpha
	)

	_target_scale = lerpf(1.0, max_scale, intensity)
	_current_scale = maxf(
		_current_scale,
		_target_scale
	)

	_hold_remaining_s = hold_duration_s


func _get_source_direction(
	damage_info: DamageInfo
) -> Vector3:
	if damage_info.source != null:
		var source_node_3d: Node3D = damage_info.source as Node3D

		if source_node_3d != null:
			var direction_to_source: Vector3 = (
				source_node_3d.global_position
				- _player.global_position
			)
			direction_to_source.y = 0.0

			if direction_to_source.length_squared() > 0.0001:
				return direction_to_source.normalized()

	var incoming_direction: Vector3 = damage_info.hit_direction
	incoming_direction.y = 0.0

	if incoming_direction.length_squared() > 0.0001:
		return -incoming_direction.normalized()

	return Vector3.ZERO


func _disconnect_health_signal() -> void:
	if _health_component == null:
		return

	if _health_component.damaged.is_connected(
		_on_player_damaged
	):
		_health_component.damaged.disconnect(
			_on_player_damaged
		)


func _get_smoothing_weight(
	response_speed: float,
	delta: float
) -> float:
	return 1.0 - exp(-response_speed * delta)
