class_name PlayerDefinition
extends Resource

@export_category("Movement")
@export_range(0.0, 100.0, 0.1, "suffix:m/s") var run_speed_mps: float = 12.0
@export_range(0.0, 500.0, 0.1, "suffix:m/s²") var ground_acceleration_mps2: float = 95.0
@export_range(0.0, 500.0, 0.1, "suffix:m/s²") var ground_deceleration_mps2: float = 120.0
@export_range(0.0, 1.0, 0.01) var air_control_multiplier: float = 0.45
@export_range(0.0, 500.0, 0.1, "suffix:m/s²") var gravity_mps2: float = 35.0
@export_range(0.0, 100.0, 0.1, "suffix:m/s") var jump_velocity_mps: float = 11.0
@export_range(0.0, 1.0, 0.01) var ground_stick_velocity_mps: float = 0.5

@export_category("Camera")
@export var camera_local_position_m: Vector3 = Vector3(0.0, 0.4, 0.0)
@export var camera_projection: CameraProjectionDefinition
@export_range(0.0001, 0.1, 0.0001) var mouse_sensitivity: float = 0.0025
@export_range(0.0, 89.9, 0.1, "suffix:deg") var pitch_limit_deg: float = 85.0

@export_category("Collision")
@export_range(0.1, 10.0, 0.01, "suffix:m") var capsule_radius_m: float = 0.4
@export_range(0.2, 20.0, 0.01, "suffix:m") var capsule_height_m: float = 1.8


func validate() -> bool:
	if run_speed_mps <= 0.0:
		return false

	if capsule_radius_m <= 0.0:
		return false

	if capsule_height_m < capsule_radius_m * 2.0:
		return false

	if camera_projection == null:
		return false

	return true
