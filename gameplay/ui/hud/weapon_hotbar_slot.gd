class_name WeaponHotbarSlot
extends Control

@export_group("Node References")
@export var frame_sprite: TextureRect
@export var weapon_icon: TextureRect

@export_group("Presentation")
@export var active_modulate: Color = Color.WHITE
@export var inactive_modulate: Color = Color(0.65, 0.65, 0.65, 0.82)
@export var empty_modulate: Color = Color(0.42, 0.42, 0.42, 0.55)
@export_range(0.1, 2.0, 0.01) var active_scale: float = 1.0
@export_range(0.1, 2.0, 0.01) var inactive_scale: float = 0.84


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


func setup(weapon: WeaponInstance, is_active: bool) -> void:
	if weapon == null:
		weapon_icon.texture = null
		modulate = empty_modulate
		scale = Vector2.ONE * inactive_scale
		return

	weapon_icon.texture = weapon.definition.inventory_icon
	modulate = active_modulate if is_active else inactive_modulate
	scale = Vector2.ONE * (
		active_scale if is_active else inactive_scale
	)


func set_radial_rotation(slot_rotation_rad: float) -> void:
	rotation = slot_rotation_rad
	weapon_icon.rotation = -slot_rotation_rad
