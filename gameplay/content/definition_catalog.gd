class_name DefinitionCatalog
extends Resource

@export var definitions: Array[Resource] = []

var _definitions_by_id: Dictionary[StringName, Resource] = {}


func build_index() -> bool:
	_definitions_by_id.clear()

	for definition: Resource in definitions:
		if definition == null:
			push_error("DefinitionCatalog contains a null definition.")
			return false

		var definition_id: StringName = _get_definition_id(
			definition
		)

		if definition_id.is_empty():
			push_error(
				"DefinitionCatalog definition '%s' has an empty ID."
				% definition.resource_path
			)
			return false

		if _definitions_by_id.has(definition_id):
			push_error(
				"DefinitionCatalog has duplicate ID '%s'."
				% definition_id
			)
			return false

		_definitions_by_id[definition_id] = definition

	return true


func get_definition(
	definition_id: StringName
) -> Resource:
	return _definitions_by_id.get(definition_id)


func get_ids() -> PackedStringArray:
	var ids: PackedStringArray = []

	for definition_id: StringName in _definitions_by_id:
		ids.append(String(definition_id))

	ids.sort()
	return ids


func _get_definition_id(definition: Resource) -> StringName:
	var raw_id: Variant = definition.get("id")

	if raw_id is StringName:
		return raw_id

	if raw_id is String:
		return StringName(raw_id)

	return &""
