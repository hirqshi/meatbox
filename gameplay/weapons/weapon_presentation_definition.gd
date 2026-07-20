class_name WeaponPresentationDefinition
extends Resource

@export_category("Sprite Frames")
@export var sprite_frames: SpriteFrames

@export_category("Animations")
@export var default_animation_name: StringName = &"default"
@export var fire_animation_name: StringName = &"fire"
@export var reload_animation_name: StringName = &"reload"

@export_category("View Transform")
@export var view_offset: Vector3 = Vector3(0.28, -0.22, -0.55)
@export var view_rotation_degrees: Vector3 = Vector3.ZERO

@export_range(0.01, 10.0, 0.01)
var view_scale: float = 1.0


func get_validation_error(
	requires_reload_animation: bool
) -> String:
	if sprite_frames == null:
		return "sprite_frames must not be null."

	if not sprite_frames.has_animation(
		default_animation_name
	):
		return (
			"Missing default animation '%s'."
			% default_animation_name
		)

	if not sprite_frames.has_animation(
		fire_animation_name
	):
		return (
			"Missing fire animation '%s'."
			% fire_animation_name
		)

	if requires_reload_animation:
		if not sprite_frames.has_animation(
			reload_animation_name
		):
			return (
				"Missing reload animation '%s'."
				% reload_animation_name
			)

	if view_scale <= 0.0:
		return "view_scale must be greater than zero."

	return ""


func is_valid(
	requires_reload_animation: bool
) -> bool:
	return get_validation_error(
		requires_reload_animation
	).is_empty()
