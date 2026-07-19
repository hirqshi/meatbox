extends CharacterBody3D

signal player_ready(player: CharacterBody3D)

@export var definition: PlayerDefinition

@onready var _motor: PlayerMotor = $PlayerMotor
@onready var _look_controller: PlayerLookController = $PlayerLookController
@onready var _combat: PlayerCombat = $PlayerCombat

func _ready() -> void:
	assert(definition != null, "Player requires a PlayerDefinition.")
	assert(definition.validate(), "PlayerDefinition contains invalid values.")

	_motor.definition = definition
	_look_controller.definition = definition

	_motor.setup(self)
	_look_controller.setup(self)
	_combat.setup(self)
	
	player_ready.emit(self)


func _input(event: InputEvent) -> void:
	_look_controller.handle_input(event)
	_combat.handle_input(event)

func _physics_process(delta: float) -> void:
	_motor.physics_update(delta)
