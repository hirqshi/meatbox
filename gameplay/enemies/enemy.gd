class_name Enemy
extends CharacterBody3D

signal enemy_died(enemy: CharacterBody3D, damage_info: DamageInfo)

@export var definition: EnemyDefinition

@onready var _brain: EnemyBrain = $EnemyBrain
@onready var _health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	assert(definition != null, "Enemy requires an EnemyDefinition.")
	assert(
		definition.is_valid(),
		"Invalid enemy definition '%s': %s"
		% [definition.resource_path, definition.get_validation_error()]
	)

	_brain.definition = definition
	_health_component.died.connect(_on_health_component_died)
	_health_component.damaged.connect(_on_health_component_damaged)

func setup_target(
	target_body: CharacterBody3D,
	target_damageable: Damageable
) -> void:
	_brain.setup(self, target_body, target_damageable)


func _physics_process(delta: float) -> void:
	_brain.physics_update(delta)


func _on_health_component_died(damage_info: DamageInfo) -> void:
	_brain.set_is_enabled(false)
	enemy_died.emit(self, damage_info)
	queue_free()

func _on_health_component_damaged(
	damage_info: DamageInfo,
	applied_damage: float
) -> void:
	DeveloperConsole.log_info(
		"%s took %.1f damage from %s. HP: %.1f / %.1f"
		% [
			definition.display_name,
			applied_damage,
			damage_info.weapon_id,
			_health_component.get_current_health(),
			_health_component.get_max_health(),
		]
	)
