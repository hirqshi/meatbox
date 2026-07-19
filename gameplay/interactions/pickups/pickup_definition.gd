class_name PickupDefinition
extends Resource

@export_category("Identity")
@export var pickup_id: StringName
@export var display_name: String

@export_category("Interaction")
@export var is_auto_pickup_enabled: bool = false

@export_category("Presentation")
@export var sprite_frames: SpriteFrames
@export var animation_name: StringName = &"default"
@export var visual_scale: Vector3 = Vector3.ONE
@export var visual_offset: Vector3 = Vector3.ZERO


func get_validation_error() -> String:
	if pickup_id.is_empty():
		return "pickup_id must not be empty."

	if display_name.is_empty():
		return "display_name must not be empty."

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
