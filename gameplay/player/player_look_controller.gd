class_name PlayerLookController
extends Node

@export var definition: PlayerDefinition
@export var camera_pivot: Node3D
@export var camera: Camera3D
@export var camera_juice: CameraJuiceComponent

var _body: CharacterBody3D
var _is_enabled: bool = true
var _pitch_radians: float = 0.0
var _projection_renderer: CameraProjectionRenderer = CameraProjectionRenderer.new()


func setup(body: CharacterBody3D) -> void:
	assert(body != null, "PlayerLookController requires a CharacterBody3D.")
	assert(definition != null, "PlayerLookController requires a PlayerDefinition.")
	assert(camera_pivot != null, "PlayerLookController requires a camera pivot.")
	assert(camera != null, "PlayerLookController requires a Camera3D.")
	assert(
	camera_juice != null,
	"PlayerLookController requires a CameraJuiceComponent."
	)
	assert(definition.camera_projection != null, "PlayerDefinition requires a camera projection.")

	_body = body
	camera_pivot.position = definition.camera_local_position_m

	_projection_renderer.apply_projection(
		camera,
		definition.camera_projection
	)

	_capture_mouse()


func set_is_enabled(value: bool) -> void:
	_is_enabled = value

	if _is_enabled:
		_capture_mouse()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func handle_input(event: InputEvent) -> void:
	if not _is_enabled or _body == null or definition == null:
		return

	if event is InputEventMouseMotion:
		_apply_mouse_look(event.screen_relative)


func _apply_mouse_look(mouse_delta: Vector2) -> void:
	camera_juice.register_look_delta(mouse_delta)
	
	var yaw_delta: float = -mouse_delta.x * definition.mouse_sensitivity
	var pitch_delta: float = -mouse_delta.y * definition.mouse_sensitivity
	var pitch_limit_radians: float = deg_to_rad(definition.pitch_limit_deg)

	_body.rotate_y(yaw_delta)

	_pitch_radians = clampf(
		_pitch_radians + pitch_delta,
		-pitch_limit_radians,
		pitch_limit_radians
	)
	camera_pivot.rotation.x = _pitch_radians


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
