class_name PickupApplyResult
extends RefCounted

enum Status {
	REJECTED,
	CONSUMED,
	PARTIALLY_CONSUMED,
}

var status: Status
var accepted_amount: int = 0


func _init(
	initial_status: Status,
	initial_accepted_amount: int = 0
) -> void:
	status = initial_status
	accepted_amount = initial_accepted_amount


static func rejected() -> PickupApplyResult:
	return PickupApplyResult.new(Status.REJECTED)


static func consumed() -> PickupApplyResult:
	return PickupApplyResult.new(Status.CONSUMED)


static func partially_consumed(
	amount: int
) -> PickupApplyResult:
	return PickupApplyResult.new(
		Status.PARTIALLY_CONSUMED,
		amount
	)
