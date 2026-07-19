class_name HurtboxComponent
extends Area3D

@export_category("Target")
@export var damageable: Damageable

@export_category("Damage")
@export var damage_part_id: StringName = &"body"
@export_range(0.01, 100.0, 0.01) var damage_multiplier: float = 1.0


func _ready() -> void:
	assert(damageable != null, "HurtboxComponent requires a Damageable target.")
	assert(
		damage_multiplier > 0.0,
		"HurtboxComponent damage_multiplier must be greater than zero."
	)


func create_damage_info(
	base_damage_info: DamageInfo,
	hit_position: Vector3,
	hit_normal: Vector3
) -> DamageInfo:
	assert(base_damage_info != null, "HurtboxComponent requires DamageInfo.")

	return DamageInfo.new(
		base_damage_info.amount * damage_multiplier,
		base_damage_info.source,
		hit_position,
		hit_normal,
		base_damage_info.hit_direction,
		base_damage_info.weapon_id
	)
