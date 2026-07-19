class_name HitscanFireExecutor
extends RefCounted

signal shot_resolved(
	request: FireRequest,
	hit_position: Vector3,
	did_hit_damageable: bool
)


func fire(request: FireRequest) -> void:
	assert(request != null, "HitscanFireExecutor requires a FireRequest.")
	assert(request.source != null, "FireRequest requires a valid source.")
	assert(request.weapon != null, "FireRequest requires a WeaponInstance.")

	var weapon_definition: WeaponDefinition = request.weapon.definition
	var ray_end: Vector3 = request.origin + request.direction * weapon_definition.range_m

	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		request.origin,
		ray_end,
		weapon_definition.hit_collision_mask,
		[request.source.get_rid()]
	)
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var space_state: PhysicsDirectSpaceState3D = (
		request.source.get_world_3d().direct_space_state
	)
	var result: Dictionary = space_state.intersect_ray(query)

	if result.is_empty():
		shot_resolved.emit(request, ray_end, false)
		return

	var hit_position: Vector3 = result.get("position", ray_end) as Vector3
	var hit_normal: Vector3 = result.get("normal", Vector3.UP) as Vector3
	var collider: Object = result.get("collider") as Object
	var damageable: Damageable = _find_damageable(collider)

	if damageable == null:
		shot_resolved.emit(request, hit_position, false)
		return

	var damage_info: DamageInfo = DamageInfo.new(
		weapon_definition.damage,
		request.source,
		hit_position,
		hit_normal,
		request.direction,
		weapon_definition.weapon_id
	)
	damageable.receive_damage(damage_info)
	shot_resolved.emit(request, hit_position, true)


func _find_damageable(collider: Object) -> Damageable:
	if collider is Damageable:
		return collider as Damageable

	if collider is Node:
		var collider_node: Node = collider as Node
		return collider_node.get_node_or_null("Damageable") as Damageable

	return null
