class_name CameraProjectionRenderer
extends RefCounted


func apply_projection(
	camera: Camera3D,
	projection: CameraProjectionDefinition
) -> void:
	assert(camera != null, "CameraProjectionRenderer requires a Camera3D.")
	assert(projection != null, "CameraProjectionRenderer requires a CameraProjectionDefinition.")

	match projection.projection_mode:
		CameraProjectionDefinition.ProjectionMode.PERSPECTIVE:
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = projection.perspective_fov_deg

		CameraProjectionDefinition.ProjectionMode.ORTHOGONAL:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = projection.orthogonal_size_m

		CameraProjectionDefinition.ProjectionMode.FRUSTUM:
			camera.projection = Camera3D.PROJECTION_FRUSTUM
			camera.size = projection.frustum_size_m
			camera.frustum_offset = projection.frustum_offset

		CameraProjectionDefinition.ProjectionMode.PANINI:
			push_warning(
				"Panini projection requires PaniniCameraProjectionRenderer. "
				+ "Falling back to perspective."
			)
			camera.projection = Camera3D.PROJECTION_PERSPECTIVE
			camera.fov = projection.perspective_fov_deg
