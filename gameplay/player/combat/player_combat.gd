class_name PlayerCombat
extends Node

signal weapon_fired(weapon: WeaponInstance)
signal weapon_hit(
	weapon: WeaponInstance,
	hit_position: Vector3,
	did_hit_damageable: bool
)
signal empty_magazine_fire_attempted(
	weapon: WeaponInstance
)

@export var aim_camera: Camera3D

var _owner_body: CharacterBody3D
var _active_weapon: WeaponInstance
var _hitscan_executor: HitscanFireExecutor = (
	HitscanFireExecutor.new()
)
var _is_enabled: bool = true


func setup(owner_body: CharacterBody3D) -> void:
	assert(
		owner_body != null,
		"PlayerCombat requires a CharacterBody3D."
	)
	assert(
		aim_camera != null,
		"PlayerCombat requires an aim camera."
	)

	_owner_body = owner_body
	_hitscan_executor.shot_resolved.connect(
		_on_hitscan_shot_resolved
	)


func set_is_enabled(value: bool) -> void:
	_is_enabled = value


func set_active_weapon(weapon: WeaponInstance) -> void:
	assert(
		weapon != null,
		"PlayerCombat requires a non-null active weapon."
	)

	_active_weapon = weapon


func get_active_weapon() -> WeaponInstance:
	return _active_weapon


func handle_input(event: InputEvent) -> void:
	if not _is_enabled:
		return

	if _owner_body == null or _active_weapon == null:
		return

	if event.is_action_pressed(&"fire_primary"):
		_try_fire_active_weapon()


func _try_fire_active_weapon() -> void:
	if _active_weapon.definition.firing_mode != (
		WeaponDefinition.FiringMode.HITSCAN
	):
		push_warning(
			"PlayerCombat does not support firing mode '%s' yet."
			% WeaponDefinition.FiringMode.keys()[
				_active_weapon.definition.firing_mode
			]
		)
		return

	var current_time_s: float = (
		Time.get_ticks_msec() / 1000.0
	)

	if _active_weapon.definition.uses_ammo:
		if _active_weapon.current_ammo <= 0:
			empty_magazine_fire_attempted.emit(
				_active_weapon
			)
			return

	if not _active_weapon.can_fire(current_time_s):
		return

	var fire_request: FireRequest = FireRequest.new(
		_owner_body,
		aim_camera.global_position,
		-aim_camera.global_transform.basis.z,
		_active_weapon
	)

	_active_weapon.consume_shot(current_time_s)
	_hitscan_executor.fire(fire_request)
	weapon_fired.emit(_active_weapon)


func _on_hitscan_shot_resolved(
	request: FireRequest,
	hit_position: Vector3,
	did_hit_damageable: bool
) -> void:
	weapon_hit.emit(
		request.weapon,
		hit_position,
		did_hit_damageable
	)
