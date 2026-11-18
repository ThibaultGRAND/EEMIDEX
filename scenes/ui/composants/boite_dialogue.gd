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

var _pages: Array[String] = []
var _page: int = -1
var _ecriture: Tween
var _clignotement: Tween

@onready var _texte: Label = %Texte
@onready var _fleche: ColorRect = %Fleche

func _ready() -> void:
	_fleche.visible = false
	_texte.text = ""

## Affiche un texte ou une suite de textes. À `await` pour attendre la fin.
func afficher(contenu: Variant) -> Signal:
	_pages.clear()
	if contenu is Array:
		for page in contenu:
			_pages.append(String(page))
	else:
		_pages.append(String(contenu))
	_page = -1
	_page_suivante()
	return dialogue_termine

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
	page_ecrite.emit()
	if not attendre_validation:
		await get_tree().create_timer(pause_auto).timeout
		if est_en_cours():
			page_validee.emit()
			_page_suivante()
		return
	_fleche.visible = true
	_clignotement = create_tween().set_loops()
	_clignotement.tween_property(_fleche, "modulate:a", 0.0, 0.35)
	_clignotement.tween_property(_fleche, "modulate:a", 1.0, 0.35)

func _arreter_animations() -> void:
	if _ecriture != null and _ecriture.is_valid():
		_ecriture.kill()
	if _clignotement != null and _clignotement.is_valid():
		_clignotement.kill()
	_fleche.modulate.a = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not capture_entree or not is_visible_in_tree() or not est_en_cours():
		return
	if event.is_action_pressed("ui_accept"):
		passer()
		get_viewport().set_input_as_handled()
