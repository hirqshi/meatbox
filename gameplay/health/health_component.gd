class_name HealthComponent
extends Damageable

signal health_changed(current_health: float, max_health: float)
signal damaged(damage_info: DamageInfo, applied_damage: float)
signal damage_blocked(damage_info: DamageInfo)
signal died(damage_info: DamageInfo)

@export var definition: HealthDefinition

var _current_health: float = 0.0
var _elapsed_game_time_s: float = 0.0
var _next_damage_time_by_source_id: Dictionary[int, float] = {}
var _is_dead: bool = false
var _max_health_bonus: float = 0.0


func _ready() -> void:
	assert(definition != null, "HealthComponent requires a HealthDefinition.")
	assert(
		definition.is_valid(),
		"Invalid health definition '%s': %s"
		% [
			definition.resource_path,
			definition.get_validation_error(),
		]
	)

	_current_health = get_max_health()
	health_changed.emit(
		_current_health,
		get_max_health()
	)


func _physics_process(delta: float) -> void:
	_elapsed_game_time_s += delta


func receive_damage(damage_info: DamageInfo) -> void:
	if _is_dead:
		return

	if damage_info == null:
		push_error("HealthComponent received null DamageInfo.")
		return

	if damage_info.amount <= 0.0:
		return

	if _is_damage_blocked(damage_info):
		damage_blocked.emit(damage_info)
		return

	_apply_damage(damage_info)


func get_current_health() -> float:
	return _current_health


func set_max_health_bonus(value: float) -> void:
	var previous_max_health: float = get_max_health()

	_max_health_bonus = value

	var new_max_health: float = get_max_health()

	if _current_health > new_max_health:
		_current_health = new_max_health

	if is_equal_approx(
		previous_max_health,
		new_max_health
	):
		return

	health_changed.emit(
		_current_health,
		new_max_health
	)


func get_max_health() -> float:
	if definition == null:
		return 0.0

	return maxf(
		definition.max_health + _max_health_bonus,
		1.0
	)


func get_health_normalized() -> float:
	var max_health: float = get_max_health()

	if max_health <= 0.0:
		return 0.0

	return _current_health / max_health


func is_dead() -> bool:
	return _is_dead


func restore_full_health() -> void:
	if definition == null:
		return

	_is_dead = false
	_current_health = get_max_health()
	_next_damage_time_by_source_id.clear()

	health_changed.emit(
		_current_health,
		get_max_health()
	)
	

func restore_health(amount: float) -> float:
	if _is_dead or amount <= 0.0:
		return 0.0

	var restored_health: float = minf(
		amount,
		get_max_health() - _current_health
	)

	if restored_health <= 0.0:
		return 0.0

	_current_health += restored_health
	health_changed.emit(
		_current_health,
		get_max_health()
	)
	return restored_health
	

func _is_damage_blocked(damage_info: DamageInfo) -> bool:
	if definition.per_source_damage_cooldown_s <= 0.0:
		return false

	var source_id: int = _get_source_id(damage_info.source)
	var next_allowed_damage_time_s: float = _next_damage_time_by_source_id.get(
		source_id,
		0.0
	)

	return _elapsed_game_time_s < next_allowed_damage_time_s


func _apply_damage(damage_info: DamageInfo) -> void:
	var source_id: int = _get_source_id(damage_info.source)
	var applied_damage: float = minf(damage_info.amount, _current_health)

	_current_health -= applied_damage
	_next_damage_time_by_source_id[source_id] = (
		_elapsed_game_time_s + definition.per_source_damage_cooldown_s
	)

	damaged.emit(damage_info, applied_damage)
	health_changed.emit(_current_health, definition.max_health)

	if _current_health > 0.0:
		return

	_is_dead = true
	died.emit(damage_info)


func _get_source_id(source: Node) -> int:
	if source == null:
		return 0

	return source.get_instance_id()
