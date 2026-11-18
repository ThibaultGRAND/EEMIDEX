class_name Tram
extends Node2D
## Un tramway qui circule sur les rails ("r") : il occupe LONGUEUR cases d'affilee,
## avance d'une case a la fois et repart dans l'autre sens au terminus.
## Il ne connait pas la carte : il signale qu'il veut avancer (envie_d_avancer) et
## c'est world.gd qui l'autorise (avancer) ou le fait patienter (attendre).

signal envie_d_avancer(tram: Tram)

const LONGUEUR := 3
const DUREE_CASE := 0.22
const PAUSE_TERMINUS := 2.0
const PAUSE_BLOQUE := 0.4

## Les cases de la ligne, dans l'ordre.
var trajet: Array[Vector2i] = []
## Cases occupees, de l'avant vers l'arriere.
var cases: Array[Vector2i] = []

var _tete: int = 0
var _sens: int = 1
var _tween: Tween

@onready var _sprite: Sprite2D = %Sprite
@onready var _minuteur: Timer = %Minuteur

func _ready() -> void:
	_minuteur.timeout.connect(_sur_minuteur)

## Pose le tram sur sa ligne, la tete a l'indice donne, et le met en route.
func demarrer(ligne: Array[Vector2i], tete: int) -> void:
	trajet = ligne
	_tete = clampi(tete, LONGUEUR - 1, trajet.size() - 1)
	_sens = 1
	_occuper()
	position = _centre()
	_orienter()
	_minuteur.start(randf_range(0.2, 1.5))

## La case ou il entrera au prochain pas (en faisant demi-tour au terminus).
func prochaine_case() -> Vector2i:
	if _tete + _sens < 0 or _tete + _sens >= trajet.size():
		_tete -= _sens * (LONGUEUR - 1)      # l'arriere devient l'avant
		_sens = -_sens
		_occuper()
	return trajet[_tete + _sens]

func avancer() -> void:
	_tete += _sens
	_occuper()
	_orienter()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", _centre(), DUREE_CASE)
	var terminus := _tete + _sens < 0 or _tete + _sens >= trajet.size()
	_minuteur.start(DUREE_CASE + (PAUSE_TERMINUS if terminus else 0.0))

## La voie est occupee : on retente un peu plus tard.
func attendre() -> void:
	_minuteur.start(PAUSE_BLOQUE)

func _sur_minuteur() -> void:
	envie_d_avancer.emit(self)

func _occuper() -> void:
	cases.clear()
	for k in LONGUEUR:
		cases.append(trajet[_tete - _sens * k])

func _centre() -> Vector2:
	return (Joueur.centre_de(cases[0]) + Joueur.centre_de(cases[-1])) / 2.0

## L'image regarde vers le bas : on la tourne dans le sens de la marche.
func _orienter() -> void:
	var d := cases[0] - cases[1]
	if d == Vector2i.DOWN:
		_sprite.rotation = 0.0
	elif d == Vector2i.UP:
		_sprite.rotation = PI
	elif d == Vector2i.RIGHT:
		_sprite.rotation = -PI / 2.0
	else:
		_sprite.rotation = PI / 2.0
