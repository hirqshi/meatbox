class_name CombatTarget
extends StaticBody3D

@onready var _health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	_health_component.damaged.connect(_on_health_component_damaged)
	_health_component.died.connect(_on_health_component_died)


func _on_health_component_damaged(
	damage_info: DamageInfo,
	applied_damage: float
) -> void:
	DeveloperConsole.log_info(
		"Target hit in %s by %s for %.1f damage. HP: %.1f / %.1f"
		% [
			damage_info.weapon_id,
			damage_info.weapon_id,
			applied_damage,
			_health_component.get_current_health(),
			_health_component.get_max_health(),
		]
	)


func _on_health_component_died(_damage_info: DamageInfo) -> void:
	queue_free()
