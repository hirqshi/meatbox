class_name PlayerStatModifiers
extends Node

signal modifiers_changed

var _max_health_bonus: float = 0.0
var _move_speed_bonus_m_per_s: float = 0.0
var _jump_velocity_bonus_m_per_s: float = 0.0


func set_organ_bonuses(
	max_health_bonus: float,
	move_speed_bonus_m_per_s: float,
	jump_velocity_bonus_m_per_s: float
) -> void:
	var did_change: bool = (
		not is_equal_approx(
			_max_health_bonus,
			max_health_bonus
		)
		or not is_equal_approx(
			_move_speed_bonus_m_per_s,
			move_speed_bonus_m_per_s
		)
		or not is_equal_approx(
			_jump_velocity_bonus_m_per_s,
			jump_velocity_bonus_m_per_s
		)
	)

	if not did_change:
		return

	_max_health_bonus = max_health_bonus
	_move_speed_bonus_m_per_s = move_speed_bonus_m_per_s
	_jump_velocity_bonus_m_per_s = (
		jump_velocity_bonus_m_per_s
	)

	modifiers_changed.emit()


func get_max_health_bonus() -> float:
	return _max_health_bonus


func get_move_speed_bonus_m_per_s() -> float:
	return _move_speed_bonus_m_per_s


func get_jump_velocity_bonus_m_per_s() -> float:
	return _jump_velocity_bonus_m_per_s
