class_name WeaponView
extends Node3D

@onready var _visual: AnimatedSprite3D = $Visual

var _weapon_controller: WeaponController
var _combat: PlayerCombat
var _active_weapon: WeaponInstance


func _ready() -> void:
	_visual.animation_finished.connect(
		_on_visual_animation_finished
	)

	_visual.visible = false


func setup(
	weapon_controller: WeaponController,
	combat: PlayerCombat
) -> void:
	assert(
		weapon_controller != null,
		"WeaponView requires a WeaponController."
	)
	assert(
		combat != null,
		"WeaponView requires a PlayerCombat."
	)

	_disconnect_signals()

	_weapon_controller = weapon_controller
	_combat = combat

	_weapon_controller.active_weapon_changed.connect(
		_on_active_weapon_changed
	)
	_weapon_controller.weapon_reload_started.connect(
		_on_weapon_reload_started
	)
	_weapon_controller.weapon_reload_finished.connect(
		_on_weapon_reload_finished
	)
	_weapon_controller.weapon_reload_cancelled.connect(
		_on_weapon_reload_cancelled
	)

	_combat.weapon_fired.connect(_on_weapon_fired)

	_set_active_weapon(
		_weapon_controller.get_active_weapon()
	)


func _on_active_weapon_changed(
	_active_slot_index: int,
	weapon: WeaponInstance
) -> void:
	_set_active_weapon(weapon)


func _on_weapon_fired(
	weapon: WeaponInstance
) -> void:
	if weapon != _active_weapon:
		return

	_play_animation(
		weapon.definition.view_presentation.fire_animation_name,
		true
	)


func _on_weapon_reload_started(
	weapon: WeaponInstance
) -> void:
	if weapon != _active_weapon:
		return

	_play_animation(
		weapon.definition.view_presentation.reload_animation_name,
		true
	)


func _on_weapon_reload_finished(
	weapon: WeaponInstance
) -> void:
	if weapon != _active_weapon:
		return

	_play_default_animation()


func _on_weapon_reload_cancelled(
	weapon: WeaponInstance
) -> void:
	if weapon != _active_weapon:
		return

	_play_default_animation()


func _on_visual_animation_finished() -> void:
	if _active_weapon == null:
		return

	if _active_weapon.is_reloading:
		return

	_play_default_animation()


func _set_active_weapon(
	weapon: WeaponInstance
) -> void:
	_active_weapon = weapon

	if _active_weapon == null:
		_visual.visible = false
		return

	var presentation: WeaponPresentationDefinition = (
		_active_weapon.definition.view_presentation
	)

	if presentation == null:
		_visual.visible = false
		return

	_visual.visible = true
	_visual.sprite_frames = presentation.sprite_frames

	position = presentation.view_offset
	rotation_degrees = presentation.view_rotation_degrees
	scale = Vector3.ONE * presentation.view_scale

	_play_default_animation()


func _play_default_animation() -> void:
	if _active_weapon == null:
		return

	var presentation: WeaponPresentationDefinition = (
		_active_weapon.definition.view_presentation
	)

	if presentation == null:
		return

	_play_animation(
		presentation.default_animation_name,
		true
	)


func _play_animation(
	animation_name: StringName,
	restart: bool
) -> void:
	if _visual.sprite_frames == null:
		return

	if not _visual.sprite_frames.has_animation(
		animation_name
	):
		return

	if restart:
		_visual.stop()
		_visual.frame = 0

	_visual.play(animation_name)


func _disconnect_signals() -> void:
	if _weapon_controller != null:
		if _weapon_controller.active_weapon_changed.is_connected(
			_on_active_weapon_changed
		):
			_weapon_controller.active_weapon_changed.disconnect(
				_on_active_weapon_changed
			)

		if _weapon_controller.weapon_reload_started.is_connected(
			_on_weapon_reload_started
		):
			_weapon_controller.weapon_reload_started.disconnect(
				_on_weapon_reload_started
			)

		if _weapon_controller.weapon_reload_finished.is_connected(
			_on_weapon_reload_finished
		):
			_weapon_controller.weapon_reload_finished.disconnect(
				_on_weapon_reload_finished
			)

		if _weapon_controller.weapon_reload_cancelled.is_connected(
			_on_weapon_reload_cancelled
		):
			_weapon_controller.weapon_reload_cancelled.disconnect(
				_on_weapon_reload_cancelled
			)

	if _combat != null:
		if _combat.weapon_fired.is_connected(
			_on_weapon_fired
		):
			_combat.weapon_fired.disconnect(
				_on_weapon_fired
			)
