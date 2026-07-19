class_name DamageInfo
extends RefCounted

var amount: float
var source: Node
var hit_position: Vector3
var hit_normal: Vector3
var hit_direction: Vector3
var weapon_id: StringName


func _init(
	initial_amount: float,
	initial_source: Node,
	initial_hit_position: Vector3,
	initial_hit_normal: Vector3,
	initial_hit_direction: Vector3,
	initial_weapon_id: StringName
) -> void:
	amount = initial_amount
	source = initial_source
	hit_position = initial_hit_position
	hit_normal = initial_hit_normal
	hit_direction = initial_hit_direction
	weapon_id = initial_weapon_id
