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
		enfant.queue_free()
	for option in _options:
		_grille.add_child(_fabriquer_ligne(option))
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
	_index = clampi(nouvel_index, 0, _options.size() - 1)
	_rafraichir()
	choix_change.emit(_index, option_courante().get("id", &""))

## Valide l'option sous le curseur, comme si le joueur appuyait sur Entrée.
func valider() -> void:
	var option := option_courante()
	if option.is_empty() or not option.get("actif", true):
		return
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

func _fabriquer_ligne(option: Dictionary) -> HBoxContainer:
	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 2)
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
	for i in _grille.get_child_count():
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

func _unhandled_input(event: InputEvent) -> void:
	if not interactif or not is_visible_in_tree() or _options.is_empty():
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
		valider()
	elif event.is_action_pressed("ui_cancel"):
		annule.emit()
	else:
		return
	get_viewport().set_input_as_handled()
