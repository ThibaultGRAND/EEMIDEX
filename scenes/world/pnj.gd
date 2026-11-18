class_name Pnj
extends Node2D
## Un PNJ qui se balade sur la carte, case par case.
## Il ne connait pas la carte : il signale qu'il veut bouger, et c'est la carte
## (world.gd) qui choisit la case et l'appelle avec avancer_vers() ou regarder().
##
## Il marche par promenades de quelques pas d'affilee (pas_restants), puis
## s'arrete un moment. Pendant un pas : foulee, puis pose debout ; deux pas de
## suite donnent le cycle complet pied gauche / debout / pied droit / debout.

signal envie_de_bouger(pnj: Pnj)

const DUREE_PAS := 0.3
const PAUSE_MIN := 0.8
const PAUSE_MAX := 2.6

## Colonnes de la planche (hframes = 3).
const IMAGE_DEBOUT := 0
const IMAGE_FOULEE_A := 1
const IMAGE_FOULEE_B := 2

## Planche 3 images (debout, foulee A, foulee B) x 4 directions, dans l'ordre
## de Joueur.Direction ; pieds sur la derniere ligne de chaque case.
@export var sprite: Texture2D
## Distance maximale (en cases) a sa case de depart ; negatif = toute la zone.
@export var rayon: int = -1

var cellule: Vector2i = Vector2i.ZERO
var case_depart: Vector2i = Vector2i.ZERO
var direction: Joueur.Direction = Joueur.Direction.BAS
var en_mouvement: bool = false
## Pas qu'il reste a faire dans la promenade en cours (0 = a l'arret).
var pas_restants: int = 0

var _foulee_a: bool = false
var _tween: Tween

@onready var _sprite: Sprite2D = %Sprite
@onready var _minuteur: Timer = %Minuteur

func _ready() -> void:
	if sprite != null:
		_sprite.texture = sprite
	# Les pieds (derniere ligne de la case) tombent sur le bas de la case de carte.
	# L'offset est en pixels de la texture : on tient compte de l'echelle du Sprite.
	var hauteur_image: float = _sprite.texture.get_height() / float(_sprite.vframes)
	var demi_case: float = Zones.TAILLE_CASE / 2.0 / _sprite.scale.y
	_sprite.offset = Vector2(0, demi_case - hauteur_image / 2.0)
	_minuteur.timeout.connect(_sur_minuteur)
	_afficher(IMAGE_DEBOUT)
	_relancer_minuteur()

## Pose le PNJ sans animation ; cette case devient sa case de depart.
func placer(c: Vector2i) -> void:
	cellule = c
	case_depart = c
	position = Joueur.centre_de(c)

## Un pas vers une case voisine : foulee pendant la premiere moitie, debout a la fin.
func avancer_vers(c: Vector2i, vers: Joueur.Direction) -> void:
	if en_mouvement:
		return
	direction = vers
	cellule = c
	en_mouvement = true
	pas_restants = maxi(pas_restants - 1, 0)
	_foulee_a = not _foulee_a
	_afficher(IMAGE_FOULEE_A if _foulee_a else IMAGE_FOULEE_B)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var arrivee: Vector2 = Joueur.centre_de(c)
	_tween = create_tween()
	_tween.tween_property(self, "position", (position + arrivee) / 2.0, DUREE_PAS / 2.0)
	_tween.tween_callback(_afficher.bind(IMAGE_DEBOUT))
	_tween.tween_property(self, "position", arrivee, DUREE_PAS / 2.0)
	_tween.finished.connect(_sur_fin_de_pas)

## Tourner sur place ; met aussi fin a la promenade en cours.
func regarder(vers: Joueur.Direction) -> void:
	pas_restants = 0
	direction = vers
	_afficher(IMAGE_DEBOUT)

func _sur_fin_de_pas() -> void:
	en_mouvement = false
	if pas_restants > 0:
		envie_de_bouger.emit(self)       # on enchaine sans s'arreter
	if not en_mouvement:                 # promenade finie, ou pas suivant bloque
		pas_restants = 0
		_afficher(IMAGE_DEBOUT)
		_relancer_minuteur()

func _sur_minuteur() -> void:
	if en_mouvement or pas_restants > 0:
		return
	envie_de_bouger.emit(self)
	if not en_mouvement:
		_relancer_minuteur()             # il a seulement regarde autour de lui

func _relancer_minuteur() -> void:
	_minuteur.start(randf_range(PAUSE_MIN, PAUSE_MAX))

func _afficher(image: int) -> void:
	_sprite.frame = int(direction) * _sprite.hframes + image
