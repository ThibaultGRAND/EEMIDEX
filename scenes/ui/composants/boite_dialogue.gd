class_name BoiteDialogue
extends PanelContainer
## La boîte de texte du jeu : dialogues des PNJ, journal de combat, messages de
## la carte. Le texte s'écrit lettre par lettre, et le joueur valide pour
## passer à la suite.
##
## Usage, en attendant la fin :
##   await %Boite.afficher(["Bonjour.", "Vous cherchez un alternant ?"])
## Usage, sans bloquer (journal de combat) :
##   %Boite.afficher("C'est très efficace !")

## Une page vient d'être écrite en entier : la flèche clignote.
signal page_ecrite
## Le joueur a validé une page.
signal page_validee
## Plus rien à afficher.
signal dialogue_termine

## Caractères par seconde. Entrée pour tout afficher d'un coup.
@export var vitesse: float = 45.0
## false quand l'écran gère lui-même le clavier (le combat, par exemple).
@export var capture_entree: bool = true
## false pour un journal qui défile tout seul, sans appui sur Entrée.
@export var attendre_validation: bool = true
## Temps d'attente entre deux pages quand `attendre_validation` est false.
@export var pause_auto: float = 0.6

const PERIODE_CLIGNOTEMENT := 0.7

var _pages: Array[String] = []
var _page: int = -1
var _ecriture: Tween
var _temps_fleche: float = 0.0

@onready var _locuteur: Label = %Locuteur
@onready var _texte: Label = %Texte
@onready var _fleche: ColorRect = %Fleche

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fleche.visible = false
	_locuteur.visible = false
	_texte.text = ""
	set_process(false)

## Fait clignoter la flèche d'attente. Un Tween en boucle marcherait aussi,
## mais il ne s'arrête jamais : il fuit quand la scène est libérée en plein
## combat.
func _process(delta: float) -> void:
	_temps_fleche += delta
	_fleche.visible = fmod(_temps_fleche, PERIODE_CLIGNOTEMENT) < PERIODE_CLIGNOTEMENT * 0.5

## Affiche un texte ou une suite de textes. À `await` pour attendre la fin.
## `locuteur` écrit un nom au-dessus, en doré : « GÉRARD ».
func afficher(contenu: Variant, locuteur: String = "") -> Signal:
	_poser_locuteur(locuteur)
	_pages.clear()
	if contenu is Array:
		for page in contenu:
			_pages.append(String(page))
	else:
		_pages.append(String(contenu))
	_page = -1
	_page_suivante()
	return dialogue_termine

## Affiche un texte qui reste à l'écran, sans flèche et sans attendre Entrée :
## l'invite d'un menu (« Que fait Thigoat ? »). Le clavier va au menu.
func afficher_invite(texte: String, locuteur: String = "") -> void:
	_poser_locuteur(locuteur)
	_arreter_animations()
	_pages.clear()
	_page = -1
	_fleche.visible = false
	_texte.text = texte
	_texte.visible_ratio = 0.0
	_ecriture = create_tween()
	_ecriture.tween_property(_texte, "visible_ratio", 1.0,
		float(texte.length()) / maxf(vitesse, 1.0))

## Qui parle. Vide = pas de ligne de nom, la boîte garde toute sa hauteur.
func _poser_locuteur(nom: String) -> void:
	_locuteur.text = nom
	_locuteur.visible = nom != ""

## Vrai tant qu'il reste du texte à écrire ou une page à valider.
func est_en_cours() -> bool:
	return _page >= 0 and _page < _pages.size()

## Vrai quand la page est écrite et attend le joueur.
func attend_le_joueur() -> bool:
	return est_en_cours() and _texte.visible_ratio >= 1.0

## Ce que fait Entrée : finir d'écrire la page, ou passer à la suivante.
func passer() -> void:
	if not est_en_cours():
		return
	if _texte.visible_ratio < 1.0:
		_finir_ecriture()
		return
	GameState.jouer_son(&"dialogue_suivant")
	page_validee.emit()
	_page_suivante()

## Vide la boîte sans émettre quoi que ce soit.
func vider() -> void:
	_arreter_animations()
	_pages.clear()
	_page = -1
	_texte.text = ""
	_texte.visible_ratio = 1.0
	_fleche.visible = false
	_poser_locuteur("")

func _page_suivante() -> void:
	_arreter_animations()
	_fleche.visible = false
	_page += 1
	if _page >= _pages.size():
		_page = -1
		_pages.clear()
		dialogue_termine.emit()
		return
	_texte.text = _pages[_page]
	_texte.visible_ratio = 0.0
	# La machine a ecrire tourne tant que la page s'ecrit.
	GameState.demarrer_son_texte()
	var duree := float(_texte.text.length()) / maxf(vitesse, 1.0)
	_ecriture = create_tween()
	_ecriture.tween_property(_texte, "visible_ratio", 1.0, duree)
	_ecriture.finished.connect(_sur_page_ecrite)

func _finir_ecriture() -> void:
	if _ecriture != null and _ecriture.is_valid():
		_ecriture.kill()
	_texte.visible_ratio = 1.0
	_sur_page_ecrite()

func _sur_page_ecrite() -> void:
	GameState.arreter_son_texte()
	page_ecrite.emit()
	if not attendre_validation:
		var page_attendue := _page
		await get_tree().create_timer(pause_auto).timeout
		# Le joueur a pu valider pendant la pause. Si la page a changé, c'est
		# lui qui l'a tournée : tourner une deuxième fois en sauterait une.
		if _page != page_attendue or not est_en_cours():
			return
		page_validee.emit()
		_page_suivante()
		return
	_temps_fleche = 0.0
	_fleche.visible = true
	set_process(true)

func _arreter_animations() -> void:
	if _ecriture != null and _ecriture.is_valid():
		_ecriture.kill()
	GameState.arreter_son_texte()
	set_process(false)
	_fleche.visible = false

## La boite peut disparaitre en plein milieu d'une page (changement de scene
## apres un combat) : sans ca, la machine a ecrire tournerait sans fin.
func _exit_tree() -> void:
	GameState.arreter_son_texte()

## Un clic dans la boîte vaut Entrée : finir d'écrire, ou passer à la suite.
func _gui_input(event: InputEvent) -> void:
	if not capture_entree or not est_en_cours():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		var vue := get_viewport()
		passer()
		if vue != null and is_inside_tree():
			accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not capture_entree or not is_visible_in_tree() or not est_en_cours():
		return
	if event.is_action_pressed("ui_accept"):
		# On retient le viewport avant d'agir : passer() peut terminer le
		# dialogue, et l'écran qui écoute peut changer de scène dans la foulée.
		# La boîte n'est alors plus dans l'arbre et get_viewport() renvoie null.
		var vue := get_viewport()
		passer()
		if vue != null:
			vue.set_input_as_handled()
