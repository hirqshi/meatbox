class_name PlayerCombat
extends Node

signal weapon_fired(weapon: WeaponInstance)
signal weapon_hit(
	weapon: WeaponInstance,
	hit_position: Vector3,
	did_hit_damageable: bool
)

@export var finger_gun_definition: WeaponDefinition
@export var aim_camera: Camera3D

var _owner_body: CharacterBody3D
var _finger_gun: WeaponInstance
var _hitscan_executor: HitscanFireExecutor = HitscanFireExecutor.new()
var _is_enabled: bool = true


func setup(owner_body: CharacterBody3D) -> void:
	assert(owner_body != null, "PlayerCombat requires a CharacterBody3D.")
	assert(finger_gun_definition != null, "PlayerCombat requires a finger gun definition.")
	assert(
	finger_gun_definition.is_valid(),
	"Invalid finger gun definition '%s': %s"
	% [
		finger_gun_definition.resource_path,
		finger_gun_definition.get_validation_error(),
	]
	)
	assert(aim_camera != null, "PlayerCombat requires an aim camera.")
	assert(
		finger_gun_definition.firing_mode == WeaponDefinition.FiringMode.HITSCAN,
		"Current PlayerCombat setup only supports a hitscan finger gun."
	)

	_owner_body = owner_body
	_finger_gun = WeaponInstance.new(finger_gun_definition)

	_hitscan_executor.shot_resolved.connect(_on_hitscan_shot_resolved)


func set_is_enabled(value: bool) -> void:
	_is_enabled = value


func handle_input(event: InputEvent) -> void:
	if not _is_enabled or _owner_body == null or _finger_gun == null:
		return

	if event.is_action_pressed(&"fire_primary"):
		_try_fire_finger_gun()


func _try_fire_finger_gun() -> void:
	var current_time_s: float = Time.get_ticks_msec() / 1000.0

	if not _finger_gun.can_fire(current_time_s):
		return

	var fire_request: FireRequest = FireRequest.new(
		_owner_body,
		aim_camera.global_position,
		-aim_camera.global_transform.basis.z,
		_finger_gun
	)

	_finger_gun.consume_shot(current_time_s)
	_hitscan_executor.fire(fire_request)
	weapon_fired.emit(_finger_gun)


func _on_hitscan_shot_resolved(
	request: FireRequest,
	hit_position: Vector3,
	did_hit_damageable: bool
) -> void:
	weapon_hit.emit(request.weapon, hit_position, did_hit_damageable)
