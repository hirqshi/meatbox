class_name OrganDefinition
extends Resource

@export_category("Identity")
@export var organ_id: StringName
@export var display_name: String = "Unnamed Organ"
@export_multiline var description: String = ""

@export_category("Visual")
@export var visual_definition: OrganVisualDefinition
@export var grid_tint: Color = Color.WHITE

@export_category("Grid")
@export var footprint: OrganFootprint

@export_group("Rectangle Helper")
@export_range(1, 8, 1)
var grid_width_cells: int = 1

@export_range(1, 8, 1)
var grid_height_cells: int = 1

@export_category("Base Effects")
@export_range(-500.0, 500.0, 0.1, "suffix:hp")
var max_health_bonus: float = 0.0

@export_range(-20.0, 20.0, 0.01, "suffix:m/s")
var move_speed_bonus_m_per_s: float = 0.0

@export_range(-20.0, 20.0, 0.01, "suffix:m/s")
var jump_velocity_bonus_m_per_s: float = 0.0


func get_validation_error() -> String:
	if organ_id.is_empty():
		return "organ_id must not be empty."

	if display_name.is_empty():
		return "display_name must not be empty."

	if visual_definition == null:
		return "visual_definition must not be null."

	if grid_width_cells <= 0:
		return "grid_width_cells must be greater than zero."

	if grid_height_cells <= 0:
		return "grid_height_cells must be greater than zero."

	return ""


func is_valid() -> bool:
	return get_validation_error().is_empty()


func get_visual_scale() -> float:
	if visual_definition == null:
		return 1.0

	return visual_definition.visual_scale


func get_collision_scale() -> float:
	if visual_definition == null:
		return 1.0

	return visual_definition.collision_scale


func get_icon() -> Texture2D:
	if visual_definition == null:
		return null

	return visual_definition.icon


func get_footprint() -> OrganFootprint:
	if footprint != null:
		return footprint

	var generated: OrganFootprint = OrganFootprint.new()
	generated.make_rectangle(
		Vector2i(grid_width_cells, grid_height_cells)
	)
	return generated


func get_footprint_cells(
	rotation_index: int = 0
) -> Array[Vector2i]:
	return get_footprint().get_cells_rotated(rotation_index)


func get_footprint_bounds(
	rotation_index: int = 0
) -> Rect2i:
	return get_footprint().get_bounds(rotation_index)
