class_name CrosshairController
extends Control

@export_category("Fallback")
@export var fallback_presentation: CrosshairPresentationDefinition

@onready var _crosshair_pivot: Control = $CrosshairPivot
@onready var _crosshair: CrosshairLayer = (
	$CrosshairPivot/Crosshair
)
@onready var _dot: TextureRect = $Dot
@onready var _hitmarker: TextureRect = $Hitmarker

var _weapon_controller: WeaponController
var _combat: PlayerCombat
var _active_weapon: WeaponInstance

var _weapon_presentation: CrosshairPresentationDefinition
var _presentation: CrosshairPresentationDefinition

var _is_crosshair_enabled: bool = false
var _is_dot_enabled: bool = false
var _is_hitmarker_enabled: bool = false

var _current_separation_px: float = 0.0
var _target_separation_px: float = 0.0

var _is_reload_rotation_active: bool = false
var _reload_elapsed_s: float = 0.0

var _hitmarker_remaining_s: float = 0.0
var _current_hitmarker_alpha: float = 0.0
var _target_hitmarker_alpha: float = 0.0


func _ready() -> void:
	assert(
		fallback_presentation != null,
		"CrosshairController requires a fallback_presentation."
	)
	assert(
		fallback_presentation.is_valid(),
		"Invalid fallback crosshair presentation '%s': %s"
		% [
			fallback_presentation.resource_path,
			fallback_presentation.get_validation_error(),
		]
	)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_crosshair_pivot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hitmarker.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_crosshair.visible = false
	_dot.visible = false
	_hitmarker.visible = false



func setup(player: CharacterBody3D) -> void:
	if player == null:
		push_error("CrosshairController requires a player.")
		return

	var weapon_controller: WeaponController = (
		player.get_node_or_null("WeaponController")
		as WeaponController
	)

	var combat: PlayerCombat = (
		player.get_node_or_null("PlayerCombat")
		as PlayerCombat
	)

	if weapon_controller == null:
		push_error(
			"CrosshairController requires Player/WeaponController."
		)
		return

	if combat == null:
		push_error(
			"CrosshairController requires Player/PlayerCombat."
		)
		return

	_disconnect_signals()

	_weapon_controller = weapon_controller
	_combat = combat

	_weapon_controller.active_weapon_changed.connect(
		_on_active_weapon_changed
	)

	_combat.weapon_fired.connect(_on_weapon_fired)
	_combat.weapon_hit.connect(_on_weapon_hit)

	_apply_weapon(
		_weapon_controller.get_active_weapon()
	)


func _process(delta: float) -> void:
	if _presentation == null:
		return

	_update_crosshair_separation(delta)
	_update_reload_rotation(delta)
	_update_hitmarker(delta)


func _apply_weapon(weapon: WeaponInstance) -> void:
	_disconnect_active_weapon_signals()

	_active_weapon = weapon
	_weapon_presentation = _get_weapon_presentation(weapon)
	_presentation = _get_base_presentation()

	_is_crosshair_enabled = (
		_presentation.is_crosshair_enabled
	)
	_is_dot_enabled = _presentation.is_dot_enabled
	_is_hitmarker_enabled = (
		_presentation.is_hitmarker_enabled
	)

	_current_separation_px = 0.0
	_target_separation_px = 0.0

	_is_reload_rotation_active = false
	_reload_elapsed_s = 0.0

	_hitmarker_remaining_s = 0.0
	_current_hitmarker_alpha = 0.0
	_target_hitmarker_alpha = 0.0

	_connect_active_weapon_signals()
	_apply_crosshair_visual()
	_apply_dot_visual()
	_apply_hitmarker_visual()
	_apply_weapon_switch_separation()

	if _active_weapon != null:
		if _active_weapon.is_reloading:
			_on_active_weapon_reload_started()


func _apply_crosshair_visual() -> void:
	var crosshair_texture: Texture2D = (
		_resolve_crosshair_texture()
	)

	_crosshair.set_presentation(
		crosshair_texture,
		_presentation.split_mode,
		_presentation.plus_arm_thickness_px,
		_presentation.plus_center_gap_px,
		_presentation.crosshair_scale,
		_presentation.crosshair_modulate
	)

	_crosshair_pivot.rotation = 0.0
	_crosshair.visible = (
		_is_crosshair_enabled
		and crosshair_texture != null
	)


func _apply_dot_visual() -> void:
	var dot_texture: Texture2D = _resolve_dot_texture()

	_dot.texture = dot_texture
	_dot.modulate = _presentation.dot_modulate
	_dot.scale = Vector2.ONE * _presentation.dot_scale
	_dot.visible = (
		_is_dot_enabled
		and dot_texture != null
	)


func _apply_hitmarker_visual() -> void:
	var hitmarker_texture: Texture2D = (
		_resolve_hitmarker_texture()
	)

	_hitmarker.texture = hitmarker_texture
	_hitmarker.modulate = Color(
		_presentation.hitmarker_modulate.r,
		_presentation.hitmarker_modulate.g,
		_presentation.hitmarker_modulate.b,
		0.0
	)
	_hitmarker.scale = (
		Vector2.ONE
		* _presentation.hitmarker_scale
	)
	_hitmarker.visible = false


func _apply_weapon_switch_separation() -> void:
	if not _is_crosshair_enabled:
		_crosshair.set_separation_px(0.0)
		return

	if _presentation.split_mode == (
		CrosshairPresentationDefinition.SplitMode.NONE
	):
		_crosshair.set_separation_px(0.0)
		return

	if not _presentation.is_switch_enter_separation_enabled:
		_crosshair.set_separation_px(0.0)
		return

	_current_separation_px = (
		_presentation.switch_enter_separation_px
	)

	_target_separation_px = 0.0

	_crosshair.set_separation_px(
		_current_separation_px
	)


func _update_crosshair_separation(
	delta: float
) -> void:
	if not _is_crosshair_enabled:
		return

	var separation_weight: float = (
		_get_smoothing_weight(
			_presentation.separation_return_speed,
			delta
		)
	)

	_current_separation_px = lerpf(
		_current_separation_px,
		_target_separation_px,
		separation_weight
	)

	_crosshair.set_separation_px(
		_current_separation_px
	)


func _update_reload_rotation(delta: float) -> void:
	if not _is_crosshair_enabled:
		return

	if not _presentation.is_reload_rotation_enabled:
		_crosshair_pivot.rotation = 0.0
		return

	if not _is_reload_rotation_active:
		_crosshair_pivot.rotation = 0.0
		return

	var reload_duration_s: float = (
		_get_active_reload_duration_s()
	)

	if reload_duration_s <= 0.0:
		_crosshair_pivot.rotation = 0.0
		return

	_reload_elapsed_s = minf(
		_reload_elapsed_s + delta,
		reload_duration_s
	)

	var reload_progress: float = (
		_reload_elapsed_s
		/ reload_duration_s
	)

	_crosshair_pivot.rotation = TAU * reload_progress


func _update_hitmarker(delta: float) -> void:
	if not _is_hitmarker_enabled:
		return

	if _hitmarker_remaining_s > 0.0:
		_hitmarker_remaining_s = maxf(
			_hitmarker_remaining_s - delta,
			0.0
		)
	else:
		_target_hitmarker_alpha = 0.0

	var fade_weight: float = _get_smoothing_weight(
		_presentation.hitmarker_fade_speed,
		delta
	)

	_current_hitmarker_alpha = lerpf(
		_current_hitmarker_alpha,
		_target_hitmarker_alpha,
		fade_weight
	)

	_hitmarker.modulate.a = _current_hitmarker_alpha
	_hitmarker.visible = (
		_current_hitmarker_alpha > 0.01
	)


func _on_active_weapon_changed(
	_active_slot_index: int,
	weapon: WeaponInstance
) -> void:
	_apply_weapon(weapon)


func _on_weapon_fired(weapon: WeaponInstance) -> void:
	if weapon != _active_weapon:
		return

	if not _is_crosshair_enabled:
		return

	if _presentation.split_mode == (
		CrosshairPresentationDefinition.SplitMode.NONE
	):
		return

	_current_separation_px = maxf(
		_current_separation_px,
		_presentation.fire_separation_px
	)

	_target_separation_px = 0.0

	_crosshair.set_separation_px(
		_current_separation_px
	)


func _on_weapon_hit(
	weapon: WeaponInstance,
	_hit_position: Vector3,
	did_hit_damageable: bool,
	did_hit_weak_point: bool
) -> void:
	if not did_hit_damageable:
		return

	if weapon != _active_weapon:
		return

	if not _is_hitmarker_enabled:
		return

	if _hitmarker.texture == null:
		return

	var hitmarker_modulate: Color = (
		_presentation.hitmarker_modulate
	)

	if did_hit_weak_point:
		hitmarker_modulate = (
			_presentation.critical_hitmarker_modulate
		)

	_hitmarker.modulate = Color(
		hitmarker_modulate.r,
		hitmarker_modulate.g,
		hitmarker_modulate.b,
		0.0
	)

	_target_hitmarker_alpha = hitmarker_modulate.a

	_current_hitmarker_alpha = maxf(
		_current_hitmarker_alpha,
		_target_hitmarker_alpha
	)

	_hitmarker_remaining_s = (
		_presentation.hitmarker_duration_s
	)

	_hitmarker.visible = true


func _on_active_weapon_reload_started() -> void:
	if not _presentation.is_reload_rotation_enabled:
		return

	_is_reload_rotation_active = true
	_reload_elapsed_s = 0.0


func _on_active_weapon_reload_finished() -> void:
	_is_reload_rotation_active = false
	_reload_elapsed_s = 0.0
	_crosshair_pivot.rotation = 0.0


func _on_active_weapon_reload_cancelled() -> void:
	_is_reload_rotation_active = false
	_reload_elapsed_s = 0.0
	_crosshair_pivot.rotation = 0.0


func _get_weapon_presentation(
	weapon: WeaponInstance
) -> CrosshairPresentationDefinition:
	if weapon == null:
		return null

	if weapon.definition == null:
		return null

	var weapon_view_presentation: WeaponPresentationDefinition = (
		weapon.definition.view_presentation
	)

	if weapon_view_presentation == null:
		return null

	return weapon_view_presentation.crosshair_presentation


func _get_base_presentation() -> CrosshairPresentationDefinition:
	if _weapon_presentation != null:
		return _weapon_presentation

	return fallback_presentation


func _resolve_crosshair_texture() -> Texture2D:
	if (
		_weapon_presentation != null
		and _weapon_presentation.crosshair_texture != null
	):
		return _weapon_presentation.crosshair_texture

	return fallback_presentation.crosshair_texture


func _resolve_dot_texture() -> Texture2D:
	if (
		_weapon_presentation != null
		and _weapon_presentation.dot_texture != null
	):
		return _weapon_presentation.dot_texture

	return fallback_presentation.dot_texture


func _resolve_hitmarker_texture() -> Texture2D:
	if (
		_weapon_presentation != null
		and _weapon_presentation.hitmarker_texture != null
	):
		return _weapon_presentation.hitmarker_texture

	return fallback_presentation.hitmarker_texture


func _get_active_reload_duration_s() -> float:
	if _active_weapon == null:
		return 0.0

	if _active_weapon.definition == null:
		return 0.0

	return _active_weapon.definition.reload_duration_s


func _connect_active_weapon_signals() -> void:
	if _active_weapon == null:
		return

	_active_weapon.reload_started.connect(
		_on_active_weapon_reload_started
	)

	_active_weapon.reload_finished.connect(
		_on_active_weapon_reload_finished
	)

	_active_weapon.reload_cancelled.connect(
		_on_active_weapon_reload_cancelled
	)


func _disconnect_active_weapon_signals() -> void:
	if _active_weapon == null:
		return

	if _active_weapon.reload_started.is_connected(
		_on_active_weapon_reload_started
	):
		_active_weapon.reload_started.disconnect(
			_on_active_weapon_reload_started
		)

	if _active_weapon.reload_finished.is_connected(
		_on_active_weapon_reload_finished
	):
		_active_weapon.reload_finished.disconnect(
			_on_active_weapon_reload_finished
		)

	if _active_weapon.reload_cancelled.is_connected(
		_on_active_weapon_reload_cancelled
	):
		_active_weapon.reload_cancelled.disconnect(
			_on_active_weapon_reload_cancelled
		)

	_active_weapon = null


func _disconnect_signals() -> void:
	_disconnect_active_weapon_signals()

	if _weapon_controller != null:
		if _weapon_controller.active_weapon_changed.is_connected(
			_on_active_weapon_changed
		):
			_weapon_controller.active_weapon_changed.disconnect(
				_on_active_weapon_changed
			)

	if _combat != null:
		if _combat.weapon_fired.is_connected(
			_on_weapon_fired
		):
			_combat.weapon_fired.disconnect(
				_on_weapon_fired
			)

		if _combat.weapon_hit.is_connected(
			_on_weapon_hit
		):
			_combat.weapon_hit.disconnect(
				_on_weapon_hit
			)

	
func _get_smoothing_weight(
	response_speed: float,
	delta: float
) -> float:
	return 1.0 - exp(-response_speed * delta)
