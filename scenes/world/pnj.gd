class_name Pnj
extends Node2D
## Un PNJ qui se balade sur la carte, case par case, autour de sa case de depart.
## Il ne connait pas la carte : il signale qu'il veut bouger, et c'est la carte
## (world.gd) qui choisit la case et l'appelle avec avancer_vers() ou regarder().

signal envie_de_bouger(pnj: Pnj)

const DUREE_PAS := 0.3
const PAUSE_MIN := 0.8
const PAUSE_MAX := 2.6

## Planche 2 foulees x 4 directions (meme ordre que Joueur.Direction),
## pieds sur la derniere ligne de chaque case.
@export var sprite: Texture2D
## Distance maximale (en cases) a laquelle il s'eloigne de sa case de depart.
@export var rayon: int = 3

var cellule: Vector2i = Vector2i.ZERO
var case_depart: Vector2i = Vector2i.ZERO
var direction: Joueur.Direction = Joueur.Direction.BAS
var en_mouvement: bool = false

var _pas: int = 0
var _tween: Tween

@onready var _sprite: Sprite2D = %Sprite
@onready var _minuteur: Timer = %Minuteur

func _ready() -> void:
	if sprite != null:
		_sprite.texture = sprite
	# Les pieds (derniere ligne de la case) tombent sur le bas de la case de carte.
	var hauteur_image: float = _sprite.texture.get_height() / float(_sprite.vframes)
	_sprite.offset = Vector2(0, Zones.TAILLE_CASE / 2.0 - hauteur_image / 2.0)
	_minuteur.timeout.connect(_sur_minuteur)
	_rafraichir_image()
	_relancer_minuteur()

## Pose le PNJ sans animation ; cette case devient le centre de sa balade.
func placer(c: Vector2i) -> void:
	cellule = c
	case_depart = c
	position = Joueur.centre_de(c)

func avancer_vers(c: Vector2i, vers: Joueur.Direction) -> void:
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
	_tween.tween_property(self, "position", Joueur.centre_de(c), DUREE_PAS)
	_tween.finished.connect(_sur_fin_de_pas)

func regarder(vers: Joueur.Direction) -> void:
	if direction != vers:
		direction = vers
		_rafraichir_image()

func _sur_fin_de_pas() -> void:
	en_mouvement = false

func _sur_minuteur() -> void:
	if not en_mouvement:
		envie_de_bouger.emit(self)
	_relancer_minuteur()

func _relancer_minuteur() -> void:
	_minuteur.start(randf_range(PAUSE_MIN, PAUSE_MAX))

func _rafraichir_image() -> void:
	_sprite.frame = int(direction) * _sprite.hframes + _pas
