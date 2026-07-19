class_name Main
extends Control

@onready var _gameplay_viewport: SubViewport = (
	$ScreenSplit/GameplayFrame/GameplayViewportContainer/GameplayViewport
)


func _ready() -> void:
	assert(
		_gameplay_viewport != null,
		"Main requires a GameplayViewport."
	)
