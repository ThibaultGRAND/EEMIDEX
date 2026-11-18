extends Node2D
## Tab : passer le contrôle d'un personnage à l'autre.

## Tous les CharacterBody2D enfants directs de la scène sont jouables.
@onready var characters: Array = get_children().filter(func(n): return n is CharacterBody2D)
var current := 0


func _ready() -> void:
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		current = (current + 1) % characters.size()
		_apply()


func _apply() -> void:
	for i in characters.size():
		characters[i].controllable = (i == current)
