class_name WeaponHotbarSlot
extends Control

@export_group("Node References")
@export var frame_sprite: TextureRect
@export var weapon_icon: TextureRect

@export_group("Slot Presentation")
@export var active_slot_modulate: Color = Color.WHITE

@export var inactive_slot_modulate: Color = Color(
	0.72,
	0.72,
	0.72,
	0.82
)

@export var empty_slot_modulate: Color = Color(
	0.42,
	0.42,
	0.42,
	0.55
)

@export_range(0.0, 2.0, 0.01, "suffix:s")
var slot_transition_duration_s: float = 0.14

@export var slot_transition: Tween.TransitionType = (
	Tween.TRANS_QUART
)

@export var slot_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Icon Presentation")
@export var active_icon_modulate: Color = Color.WHITE

@export var inactive_icon_modulate: Color = Color(
	0.72,
	0.72,
	0.72,
	0.68
)

@export var empty_icon_modulate: Color = Color(
	0.42,
	0.42,
	0.42,
	0.55
)

@export_range(0.1, 5.0, 0.01)
var active_icon_scale: float = 1.16

@export_range(0.1, 5.0, 0.01)
var inactive_icon_scale: float = 0.96

@export_range(0.0, 2.0, 0.01, "suffix:s")
var icon_transition_duration_s: float = 0.14

@export var icon_transition: Tween.TransitionType = (
	Tween.TRANS_QUART
)

@export var icon_ease: Tween.EaseType = Tween.EASE_OUT

var _current_weapon: WeaponInstance
var _is_active: bool = false
var _current_rarity_color: Color = Color.WHITE
var _slot_tween: Tween
var _icon_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	assert(
		frame_sprite != null,
		"WeaponHotbarSlot requires FrameSprite."
	)
	assert(
		weapon_icon != null,
		"WeaponHotbarSlot requires WeaponIcon."
	)

	frame_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weapon_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(
	weapon: WeaponInstance,
	is_active: bool,
	rarity_color: Color
) -> void:
	var weapon_changed: bool = weapon != _current_weapon
	var active_changed: bool = is_active != _is_active
	var rarity_changed: bool = rarity_color != _current_rarity_color

	_current_weapon = weapon
	_is_active = is_active
	_current_rarity_color = rarity_color

	if weapon == null:
		weapon_icon.texture = null
		_apply_slot_presentation(empty_slot_modulate)
		_apply_empty_icon_presentation()
		return

	if weapon_changed:
		weapon_icon.texture = weapon.definition.inventory_icon

	if not weapon_changed and not active_changed and not rarity_changed:
		return

	var target_slot_modulate: Color = (
		active_slot_modulate
		if _is_active
		else inactive_slot_modulate
	)

	_apply_slot_presentation(target_slot_modulate)
	_apply_weapon_icon_presentation()


func set_radial_rotation(slot_rotation_rad: float) -> void:
	rotation = slot_rotation_rad
	weapon_icon.rotation = -slot_rotation_rad


func _apply_slot_presentation(
	target_modulate: Color
) -> void:
	_kill_slot_tween()

	if is_zero_approx(slot_transition_duration_s):
		frame_sprite.self_modulate = target_modulate
		return

	_slot_tween = create_tween()
	_slot_tween.set_trans(slot_transition)
	_slot_tween.set_ease(slot_ease)

	_slot_tween.tween_property(
		frame_sprite,
		"self_modulate",
		target_modulate,
		slot_transition_duration_s
	)


func _apply_empty_icon_presentation() -> void:
	_kill_icon_tween()

	weapon_icon.modulate = empty_icon_modulate
	weapon_icon.scale = Vector2.ONE * inactive_icon_scale


func _apply_weapon_icon_presentation() -> void:
	var icon_state_modulate: Color = (
		active_icon_modulate
		if _is_active
		else inactive_icon_modulate
	)

	var target_icon_modulate: Color = Color(
		_current_rarity_color.r
		* icon_state_modulate.r,
		_current_rarity_color.g
		* icon_state_modulate.g,
		_current_rarity_color.b
		* icon_state_modulate.b,
		icon_state_modulate.a
	)

	var target_icon_scale: Vector2 = Vector2.ONE * (
		active_icon_scale
		if _is_active
		else inactive_icon_scale
	)

	_kill_icon_tween()

	if is_zero_approx(icon_transition_duration_s):
		weapon_icon.modulate = target_icon_modulate
		weapon_icon.scale = target_icon_scale
		return

	_icon_tween = create_tween()
	_icon_tween.set_parallel(true)
	_icon_tween.set_trans(icon_transition)
	_icon_tween.set_ease(icon_ease)

	_icon_tween.tween_property(
		weapon_icon,
		"modulate",
		target_icon_modulate,
		icon_transition_duration_s
	)

	_icon_tween.tween_property(
		weapon_icon,
		"scale",
		target_icon_scale,
		icon_transition_duration_s
	)


func _kill_slot_tween() -> void:
	if _slot_tween != null and _slot_tween.is_valid():
		_slot_tween.kill()

	_slot_tween = null


func _kill_icon_tween() -> void:
	if _icon_tween != null and _icon_tween.is_valid():
		_icon_tween.kill()

	_icon_tween = null
