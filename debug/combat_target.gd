class_name CombatTarget
extends Damageable

@export_range(1.0, 100000.0, 1.0) var max_health: float = 50.0

var _current_health: float


func _ready() -> void:
	_current_health = max_health


func receive_damage(damage_info: DamageInfo) -> void:
	_current_health = maxf(_current_health - damage_info.amount, 0.0)

	DeveloperConsole.log_info(
		"Target hit by %s for %.1f damage. HP: %.1f / %.1f"
		% [
			damage_info.weapon_id,
			damage_info.amount,
			_current_health,
			max_health,
		]
	)

	if _current_health <= 0.0:
		queue_free()
