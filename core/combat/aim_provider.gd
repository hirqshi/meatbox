class_name AimProvider
extends RefCounted


func get_aim_origin() -> Vector3:
	push_error("AimProvider.get_aim_origin() must be overridden.")
	return Vector3.ZERO


func get_aim_direction() -> Vector3:
	push_error("AimProvider.get_aim_direction() must be overridden.")
	return Vector3.FORWARD
