extends CharacterBody3D

signal player_ready(player: CharacterBody3D)
signal player_died(damage_info: DamageInfo)

@export var definition: PlayerDefinition

@onready var _motor: PlayerMotor = $PlayerMotor
@onready var _look_controller: PlayerLookController = $PlayerLookController
@onready var _combat: PlayerCombat = $PlayerCombat
@onready var _health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	assert(definition != null, "Player requires a PlayerDefinition.")
	assert(definition.validate(), "PlayerDefinition contains invalid values.")

	_motor.definition = definition
	_look_controller.definition = definition

	_motor.setup(self)
	_look_controller.setup(self)
	_combat.setup(self)

	_health_component.died.connect(_on_health_component_died)
	_health_component.health_changed.connect(_on_health_changed)
	_health_component.damaged.connect(_on_health_component_damaged)
	_health_component.damage_blocked.connect(_on_damage_blocked)
	
	player_ready.emit(self)


func _input(event: InputEvent) -> void:
	if _health_component.is_dead():
		return

	_look_controller.handle_input(event)
	_combat.handle_input(event)


func _physics_process(delta: float) -> void:
	if _health_component.is_dead():
		return

	_motor.physics_update(delta)


func _on_health_component_died(damage_info: DamageInfo) -> void:
	_motor.set_is_enabled(false)
	_look_controller.set_is_enabled(false)
	_combat.set_is_enabled(false)

	DeveloperConsole.log_info(
		"Player died. Source: %s"
		% _get_damage_source_name(damage_info.source)
	)
	player_died.emit(damage_info)


func _get_damage_source_name(source: Node) -> String:
	if source == null:
		return "unknown"

	return source.name

func _on_health_changed(current_health: float, max_health: float) -> void:
	DeveloperConsole.log_info(
		"Player health: %.1f / %.1f"
		% [current_health, max_health]
	)


func _on_health_component_damaged(
	damage_info: DamageInfo,
	applied_damage: float
) -> void:
	DeveloperConsole.log_info(
		"Player took %.1f damage from %s."
		% [applied_damage, _get_damage_source_name(damage_info.source)]
	)


func _on_damage_blocked(damage_info: DamageInfo) -> void:
	DeveloperConsole.log_info(
		"Player damage blocked from %s."
		% _get_damage_source_name(damage_info.source)
	)
