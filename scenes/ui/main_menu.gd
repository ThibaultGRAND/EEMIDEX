extends Control
## Écran titre : nouvelle partie ou reprise de la sauvegarde.

const ENTREE_NOUVELLE := "Nouvelle partie"
const ENTREE_CONTINUER := "Continuer"

var _options: Array[String] = []
var _index: int = 0

@onready var _menu: Label = %Menu

func _ready() -> void:
	_options.clear()
	if GameState.sauvegarde_existe():
		_options.append(ENTREE_CONTINUER)
	_options.append(ENTREE_NOUVELLE)
	_index = 0
	_rafraichir()

func _rafraichir() -> void:
	var lignes: Array[String] = []
	for i in _options.size():
		lignes.append(("> %s" % _options[i]) if i == _index else ("  %s" % _options[i]))
	_menu.text = "\n".join(lignes)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_index = (_index + 1) % _options.size()
		_rafraichir()
	elif event.is_action_pressed("ui_up"):
		_index = (_index - 1 + _options.size()) % _options.size()
		_rafraichir()
	elif event.is_action_pressed("ui_accept"):
		_valider()

func _valider() -> void:
	match _options[_index]:
		ENTREE_CONTINUER:
			if not GameState.charger():
				GameState.nouvelle_partie()
		ENTREE_NOUVELLE:
			GameState.nouvelle_partie()
	get_tree().change_scene_to_file(GameState.SCENE_MONDE)
