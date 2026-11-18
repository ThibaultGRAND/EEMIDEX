class_name ListeMenu
extends PanelContainer
## Une liste de choix avec un curseur, au clavier. Elle remplace les menus
## écrits dans un seul Label (« > Attaquer\n  Sac »).
##
## Elle ne décide rien : elle émet `choix_valide` et l'écran fait le reste.
##
## Usage :
##   %Menu.definir_options([{"id": &"attaquer", "texte": "Attaquer"}, "Fuite"])
##   %Menu.choix_valide.connect(_sur_choix)

signal choix_change(index: int, id: StringName)
signal choix_valide(index: int, id: StringName)
## Le joueur a appuyé sur Échap / retour. L'écran décide s'il ferme ou non.
signal annule

## Hauteur d'une ligne, en pixels. La police fait 8 : le reste est de la marge
## pour que la ligne reste cliquable sans viser au pixel près.
const HAUTEUR_LIGNE := 10

## 2 pour le menu de combat (Attaquer / Sac — Équipe / Fuite), 1 ailleurs.
@export_range(1, 4) var colonnes: int = 1:
	set(valeur):
		colonnes = valeur
		if is_node_ready():
			_grille.columns = colonnes
## false pendant une animation : la liste ignore le clavier.
@export var interactif: bool = true
## Le curseur repasse en haut quand on dépasse la dernière entrée.
@export var boucle: bool = true

var _options: Array[Dictionary] = []
var _index: int = 0

@onready var _grille: GridContainer = %Grille

func _ready() -> void:
	_grille.columns = colonnes

## Remplit la liste. Chaque option est un texte, ou un dictionnaire
## {"id": StringName, "texte": String, "actif": bool, "detail": String}.
## Une option inactive s'affiche en gris et le curseur la saute.
func definir_options(options: Array) -> void:
	_options.clear()
	for brute in options:
		_options.append(_normaliser(brute))
	for enfant in _grille.get_children():
		# remove_child tout de suite : queue_free() seul laisse l'ancienne ligne
		# dans la grille jusqu'à la fin de la frame, et _rafraichir() compterait
		# des lignes qui n'ont plus d'option en face.
		_grille.remove_child(enfant)
		enfant.queue_free()
	for i in _options.size():
		_grille.add_child(_fabriquer_ligne(i, _options[i]))
	_index = _premier_actif()
	_rafraichir()

## L'index sous le curseur.
func index() -> int:
	return _index

## L'option sous le curseur, ou un dictionnaire vide si la liste est vide.
func option_courante() -> Dictionary:
	return _options[_index] if _index >= 0 and _index < _options.size() else {}

## Déplace le curseur sans valider.
func choisir(nouvel_index: int) -> void:
	if _options.is_empty():
		return
	var avant := _index
	_index = clampi(nouvel_index, 0, _options.size() - 1)
	_rafraichir()
	# Le curseur ne claque que s'il a vraiment bouge : un clic sur la ligne
	# deja sous le curseur ne doit pas sonner deux fois.
	if _index != avant:
		GameState.jouer_son(&"clic")
	choix_change.emit(_index, option_courante().get("id", &""))

## Valide l'option sous le curseur, comme si le joueur appuyait sur Entrée.
func valider() -> void:
	var option := option_courante()
	if option.is_empty() or not option.get("actif", true):
		return
	GameState.jouer_son(&"dialogue_suivant")
	choix_valide.emit(_index, option.get("id", &""))

func _normaliser(brute: Variant) -> Dictionary:
	if brute is Dictionary:
		var copie: Dictionary = brute.duplicate()
		copie["texte"] = String(copie.get("texte", ""))
		copie["id"] = StringName(copie.get("id", copie["texte"]))
		copie["actif"] = bool(copie.get("actif", true))
		copie["detail"] = String(copie.get("detail", ""))
		return copie
	var texte := String(brute)
	return {"id": StringName(texte), "texte": texte, "actif": true, "detail": ""}

func _fabriquer_ligne(index: int, option: Dictionary) -> HBoxContainer:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 2)
	ligne.custom_minimum_size = Vector2(0, HAUTEUR_LIGNE)
	ligne.mouse_filter = Control.MOUSE_FILTER_STOP
	ligne.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if option["actif"] else Control.CURSOR_ARROW)
	ligne.mouse_entered.connect(_sur_survol_souris.bind(index))
	ligne.gui_input.connect(_sur_clic.bind(index))
	var curseur := Label.new()
	curseur.name = "Curseur"
	curseur.text = " "
	curseur.custom_minimum_size = Vector2(6, 0)
	curseur.add_theme_color_override("font_color", PaletteUi.ACCENT)
	ligne.add_child(curseur)
	var texte := Label.new()
	texte.name = "Texte"
	texte.text = option["texte"]
	texte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ligne.add_child(texte)
	if option["detail"] != "":
		var detail := Label.new()
		detail.name = "Detail"
		detail.text = option["detail"]
		detail.add_theme_color_override("font_color", PaletteUi.TEXTE_DOUX)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ligne.add_child(detail)
	return ligne

func _rafraichir() -> void:
	for i in mini(_grille.get_child_count(), _options.size()):
		var ligne: Node = _grille.get_child(i)
		var actif: bool = _options[i].get("actif", true)
		var curseur: Label = ligne.get_node("Curseur")
		var texte: Label = ligne.get_node("Texte")
		curseur.text = ">" if i == _index else " "
		var couleur := PaletteUi.TEXTE_ETEINT
		if actif:
			couleur = PaletteUi.ACCENT if i == _index else PaletteUi.TEXTE
		texte.add_theme_color_override("font_color", couleur)

func _premier_actif() -> int:
	for i in _options.size():
		if _options[i].get("actif", true):
			return i
	return 0

## Avance de `pas` entrées en sautant celles qui sont inactives.
func _deplacer(pas: int) -> void:
	if _options.is_empty():
		return
	var i := _index
	for _essai in _options.size():
		i += pas
		if i < 0 or i >= _options.size():
			if not boucle:
				return
			i = posmod(i, _options.size())
		if _options[i].get("actif", true):
			choisir(i)
			return

## La souris survole une ligne : le curseur la suit, sans rien valider. Le
## clavier et la souris bougent le même curseur, il n'y en a jamais deux.
func _sur_survol_souris(index: int) -> void:
	if not _utilisable() or index == _index:
		return
	if not _options[index].get("actif", true):
		return
	choisir(index)

## Clic gauche sur une ligne : le curseur y va, puis on valide. C'est
## exactement ce que font les flèches suivies d'Entrée.
func _sur_clic(event: InputEvent, index: int) -> void:
	if not _utilisable() or not (event is InputEventMouseButton):
		return
	var clic: InputEventMouseButton = event
	if clic.button_index != MOUSE_BUTTON_LEFT or not clic.pressed:
		return
	if not _options[index].get("actif", true):
		return
	choisir(index)
	var vue := get_viewport()
	valider()
	if vue != null:
		vue.set_input_as_handled()

func _utilisable() -> bool:
	return interactif and is_visible_in_tree() and not _options.is_empty()

func _unhandled_input(event: InputEvent) -> void:
	if not _utilisable():
		return
	if event.is_action_pressed("ui_down"):
		_deplacer(colonnes)
	elif event.is_action_pressed("ui_up"):
		_deplacer(-colonnes)
	elif event.is_action_pressed("ui_right") and colonnes > 1:
		_deplacer(1)
	elif event.is_action_pressed("ui_left") and colonnes > 1:
		_deplacer(-1)
	elif event.is_action_pressed("ui_accept"):
		# Comme pour la boîte : valider() peut changer de scène, et la liste
		# n'est alors plus dans l'arbre quand on marque l'événement.
		var vue_accept := get_viewport()
		valider()
		if vue_accept != null:
			vue_accept.set_input_as_handled()
		return
	elif event.is_action_pressed("ui_cancel"):
		annule.emit()
	else:
		return
	var vue := get_viewport()
	if vue != null:
		vue.set_input_as_handled()
