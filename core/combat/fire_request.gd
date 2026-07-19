class_name FireRequest
extends RefCounted

var source: Node
var origin: Vector3
var direction: Vector3
var weapon: WeaponInstance


func _init(
	initial_source: Node,
	initial_origin: Vector3,
	initial_direction: Vector3,
	initial_weapon: WeaponInstance
) -> void:
	source = initial_source
	origin = initial_origin
	direction = initial_direction.normalized()
	weapon = initial_weapon
