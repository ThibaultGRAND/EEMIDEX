extends Node2D
## Mini-jeu « Frappe chronométrée » — entraîne l'ATTAQUE.
## On arrête un curseur qui fait des allers-retours, dans la zone cible.
## La ressource « quenelle » débloque les niveaux de difficulté (plus dur, plus payant).

const RESSOURCE := &"quenelle"
const STAT := &"attaque"
const COUPS := 3
const BARRE_X := 30.0
const BARRE_LARGEUR := 260.0
const BARRE_Y := 92.0
const BARRE_HAUTEUR := 20.0

var _gone: GoneInstance
var _niveau: int = 1
var _curseur: float = 0.0
var _sens: float = 1.0
var _vitesse: float = 1.2
var _centre: float = 0.5
var _demi_largeur: float = 0.14
var _coups_restants: int = COUPS
var _score: int = 0
var _termine: bool = false

@onready var _titre: Label = %Titre
@onready var _info: Label = %Info
@onready var _resultat: Label = %Resultat

func _ready() -> void:
	GameState.assurer_partie()
	var index := clampi(GameState.gone_a_entrainer, 0, maxi(0, GameState.equipe.size() - 1))
	if GameState.equipe.is_empty():
		_retour()
		return
	_gone = GameState.equipe[index]
	_niveau = GameState.niveau_minijeu(RESSOURCE)
	_vitesse = 0.9 + 0.4 * float(_niveau)
	_demi_largeur = 0.17 - 0.04 * float(_niveau)
	_titre.text = "Frappe chronométrée — %s (difficulté %d/3)" % [_gone.nom(), _niveau]
	_nouvelle_cible()
	_rafraichir()

func _nouvelle_cible() -> void:
	_centre = randf_range(0.2, 0.8)

func _rafraichir() -> void:
	_info.text = "Coups restants : %d     Score : %d" % [_coups_restants, _score]
	_resultat.text = "Entrée : frapper quand le curseur est dans la zone."

func _process(delta: float) -> void:
	if _termine:
		return
	_curseur += _sens * _vitesse * delta
	if _curseur >= 1.0:
		_curseur = 1.0
		_sens = -1.0
	elif _curseur <= 0.0:
		_curseur = 0.0
		_sens = 1.0
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if _termine:
			_retour()
		else:
			_frapper()
	elif event.is_action_pressed("ui_cancel") and _termine:
		_retour()

func _frapper() -> void:
	var ecart := absf(_curseur - _centre)
	var points := 0
	if ecart <= _demi_largeur * 0.35:
		points = 3
	elif ecart <= _demi_largeur * 0.7:
		points = 2
	elif ecart <= _demi_largeur:
		points = 1
	_score += points
	_coups_restants -= 1
	_nouvelle_cible()
	if _coups_restants <= 0:
		_terminer()
	else:
		_rafraichir()

func _terminer() -> void:
	_termine = true
	var gain := clampi(int(floor(float(_score) * float(_niveau) / 4.0)), 0, 3)
	if gain > 0:
		_gone.appliquer_entrainement(STAT, gain)
		GameState.equipe_modifiee.emit()
	_info.text = "Score : %d / %d" % [_score, COUPS * 3]
	if gain > 0:
		_resultat.text = "%s gagne +%d en attaque (ATT %d).\nEntrée pour revenir." % [_gone.nom(), gain, _gone.attaque()]
	else:
		_resultat.text = "Aucun gain cette fois.\nEntrée pour revenir."
	queue_redraw()

func _retour() -> void:
	get_tree().change_scene_to_file(GameState.SCENE_MONDE)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 320, 180), Color(0.0862745, 0.105882, 0.145098))
	draw_rect(Rect2(BARRE_X, BARRE_Y, BARRE_LARGEUR, BARRE_HAUTEUR), Color(0.188235, 0.223529, 0.286275))
	var zone_x := BARRE_X + (_centre - _demi_largeur) * BARRE_LARGEUR
	var zone_l := 2.0 * _demi_largeur * BARRE_LARGEUR
	draw_rect(Rect2(zone_x, BARRE_Y, zone_l, BARRE_HAUTEUR), Color(0.290196, 0.552941, 0.376471))
	var coeur_l := zone_l * 0.35
	draw_rect(Rect2(BARRE_X + _centre * BARRE_LARGEUR - coeur_l * 0.5, BARRE_Y, coeur_l, BARRE_HAUTEUR), Color(0.941176, 0.776471, 0.317647))
	var x := BARRE_X + _curseur * BARRE_LARGEUR
	draw_rect(Rect2(x - 1.0, BARRE_Y - 6.0, 3.0, BARRE_HAUTEUR + 12.0), Color(0.945098, 0.945098, 0.921569))
