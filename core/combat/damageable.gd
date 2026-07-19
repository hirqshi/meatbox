class_name Damageable
extends Node


func receive_damage(_damage_info: DamageInfo) -> void:
	push_error("Damageable.receive_damage() must be overridden.")
