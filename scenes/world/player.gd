class_name Joueur
extends Node2D
## Le joueur sur la carte : se deplace case par case, en glissant,
## et porte la camera qui suit.

signal deplacement_fini(cellule: Vector2i)

## L'ordre doit correspondre a NOMS_DIRECTIONS (noms des animations).
enum Direction { BAS, HAUT, GAUCHE, DROITE }

const DUREE_PAS := 0.25
## Nom des directions dans les animations idle_<dir> / walk_<dir>.
const NOMS_DIRECTIONS: Array[String] = ["down", "up", "left", "right"]
## Delai sans pas avant de passer en idle : evite un clignotement entre deux
## pas enchaines quand la touche reste enfoncee.
const DELAI_IDLE := 0.06

var cellule: Vector2i = Vector2i.ZERO
var direction: Direction = Direction.BAS
var en_mouvement: bool = false

var _tween: Tween
var _temps_arret: float = 0.0

@onready var _sprite: AnimatedSprite2D = %Sprite
@onready var _camera: Camera2D = %Camera

func _ready() -> void:
	_poser_heros()
	_caler_pieds()
	# Un cycle de marche (4 images) couvre deux pas.
	var fps_marche: float = _sprite.sprite_frames.get_animation_speed(&"walk_down")
	_sprite.speed_scale = 4.0 / (2.0 * DUREE_PAS) / fps_marche
	_rafraichir_image()

func _process(delta: float) -> void:
	if en_mouvement:
		_temps_arret = 0.0
		return
	_temps_arret += delta
	if _temps_arret >= DELAI_IDLE:
		_rafraichir_image()


## Le heros choisi au prologue (Moustache ou Moustachette) : sa planche et sa
## teinte viennent de GameState.HEROS, pas de la scene.
func _poser_heros() -> void:
	var fiche: Dictionary = GameState.fiche_heros()
	var planche: SpriteFrames = load(str(fiche.get("frames", "")))
	if planche != null and planche.has_animation(&"walk_down"):
		_sprite.sprite_frames = planche
	_sprite.modulate = fiche.get("teinte", Color.WHITE)

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

## Joue walk_<dir> en marche, idle_<dir> a l'arret, sans relancer l'animation en cours.
func _rafraichir_image() -> void:
	var etat := "walk" if en_mouvement else "idle"
	var nom := "%s_%s" % [etat, NOMS_DIRECTIONS[int(direction)]]
	if _sprite.animation != nom or not _sprite.is_playing():
		_sprite.play(nom)

## Le personnage se tient au milieu de sa case : l'image (pieds sur sa derniere
## ligne) est centree sur la case, sans decalage.
func _caler_pieds() -> void:
	_sprite.offset = Vector2.ZERO

## Empeche la camera de montrer le vide autour de la zone.
func borner_camera(taille_zone: Vector2i) -> void:
	_camera.limit_left = 0
	_camera.limit_top = 0
	_camera.limit_right = taille_zone.x
	_camera.limit_bottom = taille_zone.y
	_camera.reset_smoothing()
	_camera.make_current()
