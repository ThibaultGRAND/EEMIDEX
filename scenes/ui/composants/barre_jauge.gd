class_name BarreJauge
extends Control
## Une jauge en pixel art : Motivation, Café, ou n'importe quelle valeur sur un
## maximum. Elle s'anime toute seule quand la valeur change.
##
## La couleur suit ce qu'il reste (verte, jaune, rouge) sauf si `couleur_fixe`
## est opaque — c'est ce qu'on fait pour la jauge de Café, toujours brune.
##
## Usage :
##   %Motivation.definir(gone.pv, gone.pv_max())
##   await %Motivation.animation_terminee

signal animation_terminee
## La jauge vient d'atteindre zéro à l'écran (fin de l'animation).
signal videe

const DUREE_PAR_UNITE := 0.02
const DUREE_MIN := 0.12
const DUREE_MAX := 0.7

## Opaque = cette couleur et rien d'autre. Transparent = vert/jaune/rouge.
@export var couleur_fixe: Color = Color(0, 0, 0, 0):
	set(valeur):
		couleur_fixe = valeur
		_redessiner()
@export var valeur: int = 1
@export var maximum: int = 1

var _ratio_affiche: float = 1.0
var _animation: Tween

@onready var _creux: ColorRect = %Creux
@onready var _remplissage: ColorRect = %Remplissage

func _ready() -> void:
	resized.connect(_redessiner)
	_ratio_affiche = _ratio_cible()
	_redessiner()

## Pose une nouvelle valeur. `anime` à false pour un changement d'écran.
func definir(p_valeur: int, p_maximum: int, anime: bool = true) -> void:
	valeur = maxi(p_valeur, 0)
	maximum = maxi(p_maximum, 1)
	var cible := _ratio_cible()
	if _animation != null and _animation.is_valid():
		_animation.kill()
	if not anime or not is_inside_tree():
		_appliquer_ratio(cible)
		animation_terminee.emit()
		if cible <= 0.0:
			videe.emit()
		return
	var duree := clampf(absf(cible - _ratio_affiche) * maximum * DUREE_PAR_UNITE, DUREE_MIN, DUREE_MAX)
	_animation = create_tween()
	_animation.tween_method(_appliquer_ratio, _ratio_affiche, cible, duree)
	_animation.finished.connect(func() -> void:
		animation_terminee.emit()
		if cible <= 0.0:
			videe.emit()
	)

## La part affichée en ce moment, entre 0 et 1. L'animation peut être en cours.
func ratio() -> float:
	return _ratio_affiche

func _ratio_cible() -> float:
	return clampf(float(valeur) / float(maxi(maximum, 1)), 0.0, 1.0)

func _appliquer_ratio(r: float) -> void:
	_ratio_affiche = r
	_redessiner()

func _redessiner() -> void:
	if _creux == null or _remplissage == null:
		return
	var interieur := Vector2(maxf(size.x - 2.0, 0.0), maxf(size.y - 2.0, 0.0))
	_creux.position = Vector2(1, 1)
	_creux.size = interieur
	# Largeur arrondie au pixel : une jauge en 320x180 ne doit pas baver.
	var largeur := roundf(interieur.x * _ratio_affiche)
	if _ratio_affiche > 0.0:
		largeur = maxf(largeur, 1.0)
	_remplissage.position = Vector2(1, 1)
	_remplissage.size = Vector2(largeur, interieur.y)
	_remplissage.color = couleur_fixe if couleur_fixe.a > 0.0 else PaletteUi.couleur_jauge(_ratio_affiche)
