class_name Joueur
extends Node2D
## Le joueur sur la carte : se deplace case par case, en glissant,
## et porte la camera qui suit.

signal deplacement_fini(cellule: Vector2i)

## L'ordre doit correspondre aux lignes de placeholder_joueur.png.
enum Direction { BAS, HAUT, GAUCHE, DROITE }

const DUREE_PAS := 0.14

var cellule: Vector2i = Vector2i.ZERO
var direction: Direction = Direction.BAS
var en_mouvement: bool = false

var _pas: int = 0
var _tween: Tween

@onready var _sprite: Sprite2D = %Sprite
@onready var _camera: Camera2D = %Camera

func _ready() -> void:
	_rafraichir_image()

## Position en pixels du centre d'une case.
static func centre_de(c: Vector2i) -> Vector2:
	return Vector2(c.x * Zones.TAILLE_CASE + Zones.TAILLE_CASE / 2.0,
		c.y * Zones.TAILLE_CASE + Zones.TAILLE_CASE / 2.0)

## Pose le joueur sans animation : changement de zone, chargement d'une partie.
func placer(c: Vector2i) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	en_mouvement = false
	cellule = c
	position = centre_de(c)

## Fait glisser le joueur vers une case voisine.
func avancer_vers(c: Vector2i, vers: Direction) -> void:
	if en_mouvement:
		return
	direction = vers
	cellule = c
	en_mouvement = true
	_pas = 1 - _pas
	_rafraichir_image()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", centre_de(c), DUREE_PAS)
	_tween.finished.connect(_sur_fin_de_pas)

func _sur_fin_de_pas() -> void:
	en_mouvement = false
	deplacement_fini.emit(cellule)

## Tourner sur place, sans avancer : utile quand on fait face a un mur.
func regarder(vers: Direction) -> void:
	if direction != vers:
		direction = vers
		_rafraichir_image()

func _rafraichir_image() -> void:
	_sprite.frame = int(direction) * _sprite.hframes + _pas

## Empeche la camera de montrer le vide autour de la zone.
func borner_camera(taille_zone: Vector2i) -> void:
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = taille_zone.x
	_camera.limit_bottom = taille_zone.y
	_camera.reset_smoothing()
	_camera.make_current()
