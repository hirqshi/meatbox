class_name CameraProjectionDefinition
extends Resource

enum ProjectionMode {
	PERSPECTIVE,
	ORTHOGONAL,
	FRUSTUM,
	PANINI,
}

@export_category("Mode")
@export var projection_mode: ProjectionMode = ProjectionMode.PERSPECTIVE

@export_category("Perspective")
@export_range(1.0, 179.0, 0.1, "suffix:deg") var perspective_fov_deg: float = 100.0

@export_category("Orthogonal")
@export_range(0.01, 1000.0, 0.01, "suffix:m") var orthogonal_size_m: float = 10.0

@export_category("Frustum")
@export_range(0.01, 1000.0, 0.01, "suffix:m") var frustum_size_m: float = 10.0
@export var frustum_offset: Vector2 = Vector2.ZERO

@export_category("Panini")
@export_range(1.0, 179.0, 0.1, "suffix:deg") var panini_horizontal_fov_deg: float = 130.0
@export_range(0.0, 1.0, 0.01) var panini_compression: float = 0.5
@export_range(0.0, 1.0, 0.01) var panini_vertical_compression: float = 0.0
