class_name Pnj
extends Node2D
## Un PNJ qui se balade sur la carte, case par case.
## Il ne connait pas la carte : il signale qu'il veut bouger, et c'est la carte
## (world.gd) qui choisit la case et l'appelle avec avancer_vers() ou regarder().
##
## Il marche par promenades de quelques pas d'affilee (pas_restants), puis
## s'arrete un moment. Animations : celles de son SpriteFrames, au format de
## tools/decouper_planche.py (idle_<dir> et walk_<dir>).

signal envie_de_bouger(pnj: Pnj)

const DUREE_PAS := 0.3
const PAUSE_MIN := 0.8
const PAUSE_MAX := 2.6
## Nom des directions dans les animations, dans l'ordre de Joueur.Direction.
const NOMS_DIRECTIONS: Array[String] = ["down", "up", "left", "right"]

## Animations du personnage (assets/characters/<id>/<id>_frames.tres).
@export var frames: SpriteFrames
## Distance maximale (en cases) a sa case de depart ; negatif = toute la zone.
@export var rayon: int = -1

var cellule: Vector2i = Vector2i.ZERO
var case_depart: Vector2i = Vector2i.ZERO
var direction: Joueur.Direction = Joueur.Direction.BAS
var en_mouvement: bool = false
## Pas qu'il reste a faire dans la promenade en cours (0 = a l'arret).
var pas_restants: int = 0

var _tween: Tween

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _minuteur: Timer = %Minuteur

func _ready() -> void:
	if frames != null:
		_sprite.sprite_frames = frames
	_caler_pieds()
	_minuteur.timeout.connect(_sur_minuteur)
	_jouer("idle")
	_relancer_minuteur()

## Pose le PNJ sans animation ; cette case devient sa case de depart.
func placer(c: Vector2i) -> void:
	cellule = c
	case_depart = c
	position = Joueur.centre_de(c)

## Un pas vers une case voisine, en jouant l'animation de marche.
func avancer_vers(c: Vector2i, vers: Joueur.Direction) -> void:
	if en_mouvement:
		return
	direction = vers
	cellule = c
	en_mouvement = true
	pas_restants = maxi(pas_restants - 1, 0)
	_jouer("walk")
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", Joueur.centre_de(c), DUREE_PAS)
	_tween.finished.connect(_sur_fin_de_pas)

## Tourner sur place ; met aussi fin a la promenade en cours.
func regarder(vers: Joueur.Direction) -> void:
	pas_restants = 0
	direction = vers
	_jouer("idle")

func _sur_fin_de_pas() -> void:
	en_mouvement = false
	if pas_restants > 0:
		envie_de_bouger.emit(self)       # on enchaine sans couper l'animation
	if not en_mouvement:                 # promenade finie, ou pas suivant bloque
		pas_restants = 0
		_jouer("idle")
		_relancer_minuteur()

func _sur_minuteur() -> void:
	if en_mouvement or pas_restants > 0:
		return
	envie_de_bouger.emit(self)
	if not en_mouvement:
		_relancer_minuteur()             # il a seulement regarde autour de lui

func _relancer_minuteur() -> void:
	_minuteur.start(randf_range(PAUSE_MIN, PAUSE_MAX))

## Joue "idle_<dir>" ou "walk_<dir>" ; ne relance pas une animation deja en cours.
func _jouer(etat: String) -> void:
	var nom := "%s_%s" % [etat, NOMS_DIRECTIONS[int(direction)]]
	if _sprite.animation != nom or not _sprite.is_playing():
		_sprite.play(nom)

## Les pieds (bas de l'image) tombent sur le bas de la case. L'offset est en
## pixels de la texture : on tient compte de l'echelle du sprite (0.25).
func _caler_pieds() -> void:
	var image := _sprite.sprite_frames.get_frame_texture(&"idle_down", 0)
	var demi_case: float = Zones.TAILLE_CASE / 2.0 / _sprite.scale.y
	_sprite.offset = Vector2(0, demi_case - image.get_height() / 2.0)
