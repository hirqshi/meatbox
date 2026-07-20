class_name WeaponHotbar
extends Control

const INVALID_SLOT_INDEX: int = -1

const RARITY_CATALOG: RarityCatalog = preload(
	"res://data/items/rarity_catalog.tres"
)

@export_group("Scene References")
@export var wheel_sprite: TextureRect
@export var slots_root: Control
@export var pointer_sprite: TextureRect
@export var slot_scene: PackedScene

@export_group("Visual Wheel")
@export_range(3, 32, 1) var visual_slot_count: int = 8
@export_range(3, 9, 2) var pooled_slot_count: int = 5
@export_range(64.0, 2000.0, 1.0, "suffix:px") var wheel_radius_px: float = 310.0
@export_range(-360.0, 360.0, 0.1, "suffix:deg") var active_slot_angle_deg: float = 0.0
@export_range(-360.0, 360.0, 0.1, "suffix:deg") var slot_angle_offset_deg: float = 0.0
@export_range(-360.0, 360.0, 0.1, "suffix:deg") var radial_rotation_offset_deg: float = 90.0

@export_group("Slot Appearance")
@export_range(0.1, 3.0, 0.01) var slot_scale: float = 1.0
@export var show_empty_slots: bool = true

@export_group("Rotation Animation")
@export_range(0.0, 2.0, 0.01, "suffix:s") var rotation_duration_s: float = 0.18
@export var rotation_transition: Tween.TransitionType = Tween.TRANS_QUART
@export var rotation_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Pointer Tick")
@export_range(0.0, 90.0, 0.1, "suffix:deg")
var pointer_tick_angle_deg: float = 18.0

@export_range(0.0, 1.0, 0.01, "suffix:s")
var pointer_tick_out_duration_s: float = 0.06

@export_range(0.0, 1.0, 0.01, "suffix:s")
var pointer_tick_return_duration_s: float = 0.1

@export var pointer_tick_transition: Tween.TransitionType = (
	Tween.TRANS_QUART
)

@export var pointer_tick_ease: Tween.EaseType = (
	Tween.EASE_OUT
)

@export_group("Boundary Feedback")
@export_range(0.0, 90.0, 0.1, "suffix:deg")
var boundary_overscroll_deg: float = 10.0

@export_range(0.0, 1.0, 0.01, "suffix:s")
var boundary_overscroll_duration_s: float = 0.09

@export_range(0.0, 1.0, 0.01, "suffix:s")
var boundary_return_duration_s: float = 0.16

@export var boundary_transition: Tween.TransitionType = (
	Tween.TRANS_QUART
)

@export var boundary_return_ease: Tween.EaseType = (
	Tween.EASE_OUT
)

var _weapon_controller: WeaponController
var _inventory: WeaponInventory
var _pooled_slots: Array[WeaponHotbarSlot] = []
var _wheel_rotation_deg: float = 0.0
var _valid_wheel_rotation_deg: float = 0.0
var _displayed_active_slot_index: int = INVALID_SLOT_INDEX
var _rotation_tween: Tween
var _pointer_tween: Tween
var _pointer_base_rotation_deg: float = 0.0
var _boundary_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	assert(
		wheel_sprite != null,
		"WeaponHotbar requires WheelSprite."
	)
	assert(
		slots_root != null,
		"WeaponHotbar requires SlotsRoot."
	)
	assert(
		pointer_sprite != null,
		"WeaponHotbar requires PointerSprite."
	)
	assert(
		slot_scene != null,
		"WeaponHotbar requires a WeaponHotbarSlot PackedScene."
	)
	assert(
		visual_slot_count >= pooled_slot_count,
		"Visual slot count must be >= pooled slot count."
	)
	assert(
		pooled_slot_count % 2 == 1,
		"Pooled slot count must be odd."
	)

	wheel_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pointer_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer_base_rotation_deg = pointer_sprite.rotation_degrees
	pointer_sprite.pivot_offset = pointer_sprite.size * 0.5

	_create_slot_pool()


func _exit_tree() -> void:
	_disconnect_weapon_controller()


func setup(weapon_controller: WeaponController) -> void:
	assert(
		weapon_controller != null,
		"WeaponHotbar requires a WeaponController."
	)

	if _weapon_controller == weapon_controller:
		_refresh(false)
		return

	_disconnect_weapon_controller()

	_weapon_controller = weapon_controller
	_inventory = _weapon_controller.get_inventory()

	assert(
		_inventory != null,
		"WeaponHotbar requires an initialized WeaponInventory."
	)

	_weapon_controller.inventory_changed.connect(
		_on_inventory_changed
	)
	_weapon_controller.active_weapon_changed.connect(
		_on_active_weapon_changed
	)
	_weapon_controller.inventory_navigation_blocked.connect(
		_on_inventory_navigation_blocked
	)

	_refresh(false)


func _get_weapon_rarity_color(
	weapon: WeaponInstance
) -> Color:
	if weapon == null:
		return Color.WHITE

	var rarity_definition: RarityDefinition = (
		RARITY_CATALOG.get_definition(
			weapon.definition.rarity
		)
	)

	if rarity_definition == null:
		return Color.WHITE

	return rarity_definition.outline_color


func _create_slot_pool() -> void:
	if not _pooled_slots.is_empty():
		return

	for pool_index: int in range(pooled_slot_count):
		var slot: WeaponHotbarSlot = (
			slot_scene.instantiate() as WeaponHotbarSlot
		)

		assert(
			slot != null,
			"Slot Scene root must inherit WeaponHotbarSlot."
		)

		slots_root.add_child(slot)
		_pooled_slots.append(slot)


func _refresh(animate_rotation: bool) -> void:
	if _inventory == null:
		return

	var active_slot_index: int = _inventory.get_active_slot_index()
	_displayed_active_slot_index = active_slot_index

	var target_rotation_deg: float = _get_rotation_for_active_slot(
		active_slot_index
	)

	_valid_wheel_rotation_deg = target_rotation_deg

	if animate_rotation:
		_animate_to_rotation(target_rotation_deg)
		return

	_wheel_rotation_deg = target_rotation_deg
	_apply_visual_state()


func _get_rotation_for_active_slot(
	active_slot_index: int
) -> float:
	var visual_step_deg: float = 360.0 / float(visual_slot_count)
	var active_logical_angle_deg: float = (
		slot_angle_offset_deg
		+ visual_step_deg * float(active_slot_index)
	)

	return active_slot_angle_deg - active_logical_angle_deg


func _animate_to_rotation(target_rotation_deg: float) -> void:
	if _rotation_tween != null and _rotation_tween.is_valid():
		_rotation_tween.kill()

	var shortest_target_deg: float = _get_shortest_target_rotation(
		_wheel_rotation_deg,
		target_rotation_deg
	)

	if is_zero_approx(rotation_duration_s):
		_wheel_rotation_deg = shortest_target_deg
		_apply_visual_state()
		return

	_rotation_tween = create_tween()
	_rotation_tween.set_trans(rotation_transition)
	_rotation_tween.set_ease(rotation_ease)
	_rotation_tween.tween_method(
		_set_wheel_rotation_deg,
		_wheel_rotation_deg,
		shortest_target_deg,
		rotation_duration_s
	)


func _set_wheel_rotation_deg(rotation_deg: float) -> void:
	_wheel_rotation_deg = rotation_deg
	_apply_visual_state()


func _apply_visual_state() -> void:
	wheel_sprite.rotation_degrees = _wheel_rotation_deg

	if _inventory == null:
		return

	var active_slot_index: int = _inventory.get_active_slot_index()
	var pool_half_count: int = pooled_slot_count / 2

	for pool_index: int in range(_pooled_slots.size()):
		var relative_index: int = pool_index - pool_half_count
		var logical_slot_index: int = (
			active_slot_index + relative_index
		)
		var slot: WeaponHotbarSlot = _pooled_slots[pool_index]

		_apply_slot_visual(
			slot,
			logical_slot_index,
			active_slot_index
		)


func _apply_slot_visual(
	slot: WeaponHotbarSlot,
	logical_slot_index: int,
	active_slot_index: int
) -> void:
	if not _is_valid_logical_slot_index(logical_slot_index):
		slot.visible = false
		return

	var weapon: WeaponInstance = _inventory.get_weapon_at(
		logical_slot_index
	)

	if weapon == null and not show_empty_slots:
		slot.visible = false
		return

	slot.visible = true

	var visual_step_deg: float = 360.0 / float(visual_slot_count)
	var logical_slot_angle_deg: float = (
		slot_angle_offset_deg
		+ visual_step_deg * float(logical_slot_index)
	)
	var current_angle_deg: float = (
		logical_slot_angle_deg
		+ _wheel_rotation_deg
	)
	var angle_rad: float = deg_to_rad(current_angle_deg)
	var center: Vector2 = size * 0.5
	var radial_offset: Vector2 = Vector2(
		cos(angle_rad),
		sin(angle_rad)
	) * wheel_radius_px

	slot.position = (
		center
		+ radial_offset
		- slot.size * 0.5
	)
	slot.scale = Vector2.ONE * slot_scale

	var slot_rotation_rad: float = deg_to_rad(
		current_angle_deg + radial_rotation_offset_deg
	)

	slot.set_radial_rotation(slot_rotation_rad)
	slot.setup(
		weapon,
		logical_slot_index == active_slot_index,
		_get_weapon_rarity_color(weapon)
	)


func _play_pointer_tick(
	inventory_direction: int
) -> void:
	if inventory_direction == 0:
		return

	if _pointer_tween != null and _pointer_tween.is_valid():
		_pointer_tween.kill()

	if is_zero_approx(pointer_tick_angle_deg):
		pointer_sprite.rotation_degrees = (
			_pointer_base_rotation_deg
		)
		return

	# The pointer bends opposite to wheel travel.
	var tick_rotation_deg: float = (
		_pointer_base_rotation_deg
		+ signf(float(inventory_direction))
		* pointer_tick_angle_deg
	)

	pointer_sprite.rotation_degrees = (
		_pointer_base_rotation_deg
	)

	_pointer_tween = create_tween()
	_pointer_tween.set_trans(pointer_tick_transition)
	_pointer_tween.set_ease(pointer_tick_ease)

	_pointer_tween.tween_property(
		pointer_sprite,
		"rotation_degrees",
		tick_rotation_deg,
		pointer_tick_out_duration_s
	)

	_pointer_tween.set_trans(pointer_tick_transition)
	_pointer_tween.set_ease(Tween.EASE_OUT)

	_pointer_tween.tween_property(
		pointer_sprite,
		"rotation_degrees",
		_pointer_base_rotation_deg,
		pointer_tick_return_duration_s
	)


func _is_valid_logical_slot_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < _inventory.get_slot_count()


func _get_shortest_target_rotation(
	from_rotation_deg: float,
	to_rotation_deg: float
) -> float:
	var delta_deg: float = wrapf(
		to_rotation_deg - from_rotation_deg,
		-180.0,
		180.0
	)

	return from_rotation_deg + delta_deg


func _get_visual_center_slot_index() -> int:
	if _displayed_active_slot_index != INVALID_SLOT_INDEX:
		return _displayed_active_slot_index

	if _inventory == null:
		return INVALID_SLOT_INDEX

	return _inventory.get_active_slot_index()


func _disconnect_weapon_controller() -> void:
	if _weapon_controller == null:
		return

	if _weapon_controller.inventory_changed.is_connected(
		_on_inventory_changed
	):
		_weapon_controller.inventory_changed.disconnect(
			_on_inventory_changed
		)

	if _weapon_controller.active_weapon_changed.is_connected(
		_on_active_weapon_changed
	):
		_weapon_controller.active_weapon_changed.disconnect(
			_on_active_weapon_changed
		)
	if _weapon_controller.inventory_navigation_blocked.is_connected(
		_on_inventory_navigation_blocked
	):
		_weapon_controller.inventory_navigation_blocked.disconnect(
			_on_inventory_navigation_blocked
		)
		
	_weapon_controller = null
	_inventory = null


func _on_inventory_changed() -> void:
	_refresh(false)


func _on_active_weapon_changed(
	active_slot_index: int,
	_active_weapon: WeaponInstance
) -> void:
	var previous_slot_index: int = (
		_get_visual_center_slot_index()
	)

	_refresh(true)

	var direction: int = signi(
		active_slot_index - previous_slot_index
	)

	if direction != 0:
		_play_pointer_tick(direction)


func play_boundary_feedback(direction: int) -> void:
	if direction == 0:
		return

	if _rotation_tween != null and _rotation_tween.is_valid():
		_rotation_tween.kill()

	if _boundary_tween != null and _boundary_tween.is_valid():
		_boundary_tween.kill()

	if is_zero_approx(boundary_overscroll_deg):
		_set_wheel_rotation_deg(
			_valid_wheel_rotation_deg
		)
		return

	_set_wheel_rotation_deg(_valid_wheel_rotation_deg)

	var overscroll_rotation_deg: float = (
		_valid_wheel_rotation_deg
		- signf(float(direction))
		* boundary_overscroll_deg
	)

	_boundary_tween = create_tween()
	_boundary_tween.set_trans(boundary_transition)
	_boundary_tween.set_ease(Tween.EASE_OUT)

	_boundary_tween.tween_method(
		_set_wheel_rotation_deg,
		_valid_wheel_rotation_deg,
		overscroll_rotation_deg,
		boundary_overscroll_duration_s
	)

	_boundary_tween.set_trans(boundary_transition)
	_boundary_tween.set_ease(boundary_return_ease)

	_boundary_tween.tween_method(
		_set_wheel_rotation_deg,
		overscroll_rotation_deg,
		_valid_wheel_rotation_deg,
		boundary_return_duration_s
	)


func _on_inventory_navigation_blocked(
	direction: int
) -> void:
	play_boundary_feedback(direction)
