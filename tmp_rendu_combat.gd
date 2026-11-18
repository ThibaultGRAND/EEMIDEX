extends Node
func _ready() -> void:
	add_child(load("res://scenes/battle/battle.tscn").instantiate())
	await get_tree().create_timer(1.8).timeout
	_appuyer("ui_accept")
	await get_tree().create_timer(0.5).timeout
	_appuyer("ui_accept")
	await get_tree().create_timer(0.5).timeout
	_appuyer("ui_down")

func _appuyer(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	Input.parse_input_event(e)
