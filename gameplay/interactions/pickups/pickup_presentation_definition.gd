class_name PickupPresentationDefinition
extends Resource

@export_category("Interaction")
@export var is_auto_pickup_enabled: bool = false

@export_category("World Visual")
@export var sprite_frames: SpriteFrames
@export var animation_name: StringName = &"default"
@export var visual_scale: Vector3 = Vector3.ONE
@export var visual_offset: Vector3 = Vector3.ZERO


func get_validation_error() -> String:
	if sprite_frames == null:
		return "sprite_frames must not be null."

	if not sprite_frames.has_animation(animation_name):
		return (
			"sprite_frames must contain animation '%s'."
			% animation_name
		)

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()
