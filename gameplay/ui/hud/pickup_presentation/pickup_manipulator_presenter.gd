class_name PickupManipulatorPresenter
extends Control

signal pickup_animation_started(payload: PickupPayload)
signal pickup_animation_finished(payload: PickupPayload)

@export var animation_name: StringName = &"grab"

@onready var _manipulator: AnimatedSprite2D = $Manipulator

var _active_payload: PickupPayload


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	assert(
		_manipulator.sprite_frames != null,
		"Manipulator requires a SpriteFrames resource."
	)
	assert(
		_manipulator.sprite_frames.has_animation(
			animation_name
		),
		"Manipulator SpriteFrames requires animation '%s'."
		% animation_name
	)

	_manipulator.visible = false
	_manipulator.animation_finished.connect(
		_on_manipulator_animation_finished
	)


func setup(spawner: WorldPickupSpawner) -> void:
	assert(
		spawner != null,
		"PickupManipulatorPresenter requires a WorldPickupSpawner."
	)

	if spawner.pickup_spawned.is_connected(
		_on_pickup_spawned
	):
		return

	spawner.pickup_spawned.connect(_on_pickup_spawned)


func _on_pickup_spawned(pickup: WorldPickup) -> void:
	if not is_instance_valid(pickup):
		return

	pickup.collection_started.connect(
		_on_pickup_collection_started
	)


func _on_pickup_collection_started(
	_pickup: WorldPickup,
	payload: PickupPayload
) -> void:
	if payload == null:
		return

	_play(payload)


func _play(payload: PickupPayload) -> void:
	_active_payload = payload

	_manipulator.visible = true
	_manipulator.stop()
	_manipulator.frame = 0
	_manipulator.play(animation_name)

	pickup_animation_started.emit(payload)


func _on_manipulator_animation_finished() -> void:
	_manipulator.visible = false

	var finished_payload: PickupPayload = _active_payload
	_active_payload = null

	if finished_payload != null:
		pickup_animation_finished.emit(finished_payload)
