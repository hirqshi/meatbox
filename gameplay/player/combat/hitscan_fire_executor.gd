class_name HitscanFireExecutor
extends RefCounted

const MAX_RAY_HITS: int = 16

signal shot_resolved(
	request: FireRequest,
	hit_position: Vector3,
	did_hit_damageable: bool,
	did_hit_weak_point: bool
)


func fire(request: FireRequest) -> void:
	assert(request != null, "HitscanFireExecutor requires a FireRequest.")
	assert(request.source != null, "FireRequest requires a valid source.")
	assert(request.weapon != null, "FireRequest requires a WeaponInstance.")

	var weapon_definition: WeaponDefinition = request.weapon.definition
	var ray_end: Vector3 = request.origin + request.direction * weapon_definition.range_m
	var space_state: PhysicsDirectSpaceState3D = (
		request.source.get_world_3d().direct_space_state
	)

	var excluded_rids: Array[RID] = [request.source.get_rid()]
	var selected_hurtbox: HurtboxComponent
	var selected_hit_position: Vector3 = ray_end
	var selected_hit_normal: Vector3 = Vector3.UP
	var selected_damage_multiplier: float = 0.0
	var selected_damageable: Damageable
	var fallback_hit_position: Vector3 = ray_end

	for hit_index: int in MAX_RAY_HITS:
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			request.origin,
			ray_end,
			weapon_definition.hit_collision_mask,
			excluded_rids
		)
		query.collide_with_bodies = true
		query.collide_with_areas = true

		var result: Dictionary = space_state.intersect_ray(query)

		if result.is_empty():
			break

		var hit_position: Vector3 = result.get("position", ray_end) as Vector3
		var hit_normal: Vector3 = result.get("normal", Vector3.UP) as Vector3
		var hit_rid: RID = result.get("rid", RID()) as RID
		var collider: Object = result.get("collider") as Object

		fallback_hit_position = hit_position

		if collider is not HurtboxComponent:
			break

		var hurtbox: HurtboxComponent = collider as HurtboxComponent

		if hurtbox.damageable == null:
			push_error(
				"Hurtbox '%s' has no Damageable target."
				% hurtbox.get_path()
			)
			break

		if selected_damageable != null and hurtbox.damageable != selected_damageable:
			break

		if hurtbox.damage_multiplier > selected_damage_multiplier:
			selected_hurtbox = hurtbox
			selected_hit_position = hit_position
			selected_hit_normal = hit_normal
			selected_damage_multiplier = hurtbox.damage_multiplier
			selected_damageable = hurtbox.damageable

		excluded_rids.append(hit_rid)

	if selected_hurtbox == null or selected_damageable == null:
		shot_resolved.emit(
			request,
			fallback_hit_position,
			false,
			false
		)
		return

	var base_damage_info: DamageInfo = DamageInfo.new(
		weapon_definition.damage,
		request.source,
		selected_hit_position,
		selected_hit_normal,
		request.direction,
		weapon_definition.weapon_id
	)
	var modified_damage_info: DamageInfo = selected_hurtbox.create_damage_info(
		base_damage_info,
		selected_hit_position,
		selected_hit_normal
	)

	selected_damageable.receive_damage(modified_damage_info)

	var did_hit_weak_point: bool = (
		selected_hurtbox.is_weak_point()
	)

	shot_resolved.emit(
		request,
		selected_hit_position,
		true,
		did_hit_weak_point
	)
