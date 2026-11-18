extends Node2D
## Mini-jeu « Rythme » — entraîne la VITESSE.
## Des flèches descendent, on appuie sur la bonne touche quand elles passent la ligne.
## La ressource « praline » débloque les niveaux de difficulté.

const RESSOURCE := &"praline"
const STAT := &"vitesse"
## Proportions de l'ecran : le mini-jeu suit la resolution.
const LIGNE_Y := 0.733
const HAUT_Y := 0.156
const COLONNE_ECART := 0.15
const COLONNE_LARGEUR := 0.0875
const TOLERANCE := 0.18        # tolérance en secondes autour de la ligne
const DUREE_CHUTE := 1.6       # secondes entre l'apparition et la ligne
const ACTIONS := ["ui_left", "ui_down", "ui_up", "ui_right"]

var _gone: GoneInstance
var _niveau: int = 1
var _notes: Array = []         # [{"colonne": int, "temps": float, "jouee": bool}]
var _temps: float = 0.0
var _duree: float = 0.0
var _reussites: int = 0
var _total: int = 0
var _termine: bool = false

@onready var _titre: Label = %Titre
@onready var _info: Label = %Info
@onready var _resultat: Label = %Resultat

func _ready() -> void:
	GameState.assurer_partie()
	if GameState.equipe.is_empty():
		_retour()
		return
	var index := clampi(GameState.gone_a_entrainer, 0, GameState.equipe.size() - 1)
	_gone = GameState.equipe[index]
	_niveau = GameState.niveau_minijeu(RESSOURCE)
	_generer_partition()
	_titre.text = "Rythme — %s (difficulté %d/3)" % [_gone.nom(), _niveau]
	_resultat.text = "Flèches : frapper la note quand elle touche la ligne."
	_rafraichir()

func _generer_partition() -> void:
	_notes.clear()
	var intervalle := 0.85 - 0.18 * float(_niveau)   # plus le niveau est haut, plus ça va vite
	var nombre := 10 + 4 * _niveau
	var t := DUREE_CHUTE + 0.6
	for i in nombre:
		_notes.append({"colonne": randi() % ACTIONS.size(), "temps": t, "jouee": false})
		t += intervalle
	_total = nombre
	_duree = t + 0.8

func _rafraichir() -> void:
	_info.text = "Notes réussies : %d / %d" % [_reussites, _total]

func _process(delta: float) -> void:
	if _termine:
		return
	_temps += delta
	for note in _notes:
		if not note["jouee"] and _temps > float(note["temps"]) + TOLERANCE:
			note["jouee"] = true    # note manquée
	if _temps >= _duree:
		_terminer()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if _termine:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_retour()
		return
	for colonne in ACTIONS.size():
		if event.is_action_pressed(ACTIONS[colonne]):
			_frapper(colonne)
			return

func _frapper(colonne: int) -> void:
	var meilleure: Dictionary = {}
	var meilleur_ecart := 999.0
	for note in _notes:
		if note["jouee"] or int(note["colonne"]) != colonne:
			continue
		var ecart: float = absf(float(note["temps"]) - _temps)
		if ecart < meilleur_ecart:
			meilleur_ecart = ecart
			meilleure = note
	if meilleure.is_empty() or meilleur_ecart > TOLERANCE:
		return
	meilleure["jouee"] = true
	_reussites += 1
	_rafraichir()

func _terminer() -> void:
	_termine = true
	var ratio := float(_reussites) / float(maxi(1, _total))
	var gain := 0
	if ratio >= 0.9:
		gain = 2 + _niveau
	elif ratio >= 0.6:
		gain = 1 + _niveau / 2
	elif ratio >= 0.35:
		gain = 1
	if gain > 0:
		_gone.appliquer_entrainement(STAT, gain)
		GameState.equipe_modifiee.emit()
		_resultat.text = "%d%% de réussite. %s gagne +%d en vitesse (VIT %d).\nEntrée pour revenir." % [
			int(ratio * 100.0), _gone.nom(), gain, _gone.vitesse()]
	else:
		_resultat.text = "%d%% de réussite. Pas assez pour progresser.\nEntrée pour revenir." % int(ratio * 100.0)
	queue_redraw()

func _retour() -> void:
	get_tree().change_scene_to_file(GameState.SCENE_MONDE)

## Centre horizontal de chaque colonne, en pixels.
func _colonne_x(colonne: int) -> float:
	var ecran := get_viewport_rect().size
	var ecart := ecran.x * COLONNE_ECART
	var premier := ecran.x * 0.5 - ecart * (ACTIONS.size() - 1) * 0.5
	return premier + ecart * colonne

func _draw() -> void:
	var ecran := get_viewport_rect().size
	var ligne_y := ecran.y * LIGNE_Y
	var haut_y := ecran.y * HAUT_Y
	var largeur := ecran.x * COLONNE_LARGEUR
	draw_rect(Rect2(Vector2.ZERO, ecran), Color(0.0862745, 0.105882, 0.145098))
	for i in ACTIONS.size():
		draw_rect(Rect2(_colonne_x(i) - largeur * 0.5, haut_y, largeur, ligne_y - haut_y + largeur * 0.2),
			Color(0.137255, 0.164706, 0.223529))
	var bande = _colonne_x(0) - largeur
	draw_rect(Rect2(bande, ligne_y, _colonne_x(ACTIONS.size() - 1) + largeur - bande,
		maxf(2.0, ecran.y / 90.0)), Color(0.913725, 0.772549, 0.419608))
	if _termine:
		return
	for note in _notes:
		if note["jouee"]:
			continue
		var reste: float = float(note["temps"]) - _temps
		if reste > DUREE_CHUTE or reste < -0.25:
			continue
		var y: float = ligne_y - reste / DUREE_CHUTE * (ligne_y - haut_y)
		var x: float = _colonne_x(int(note["colonne"]))
		draw_rect(Rect2(x - largeur * 0.36, y - largeur * 0.18, largeur * 0.72, largeur * 0.36),
			Color(0.411765, 0.639216, 0.858824))
