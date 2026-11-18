extends Control
## Écran d'aperçu du socle d'interface. Hors jeu : il sert à voir tous les
## composants au même endroit, en 320x180, sans lancer une partie.
##
## À lancer depuis l'éditeur (F6) sur scenes/ui/apercu_ui.tscn.
## Entrée : valider. Flèches : bouger le curseur. Échap : relancer la démo.

const DEMO_MOTIVATION := [24, 17, 9, 3, 24]

var _etape: int = 0

@onready var _fiche_ennemi: FicheCombattant = %FicheEnnemi
@onready var _fiche_joueur: FicheCombattant = %FicheJoueur
@onready var _menu: ListeMenu = %Menu
@onready var _boite: BoiteDialogue = %Boite

func _ready() -> void:
	_fiche_ennemi.definir_combattant("Guignome", 7, &"design")
	_fiche_ennemi.definir_motivation(28, 28, false)
	_fiche_joueur.definir_combattant("Thigoat", 5, &"dev")
	_fiche_joueur.definir_motivation(24, 24, false)
	_fiche_joueur.definir_cafe(28, 28, false)
	_menu.definir_options([
		{"id": &"attaquer", "texte": "Attaquer"},
		{"id": &"sac", "texte": "Sac", "detail": "x3"},
		{"id": &"equipe", "texte": "Équipe"},
		{"id": &"fuite", "texte": "Fuite", "actif": false},
	])
	_menu.choix_valide.connect(_sur_choix)
	_boite.afficher("Un Guignome sauvage vous barre la route !")

func _sur_choix(_index: int, id: StringName) -> void:
	_etape += 1
	var reste: int = DEMO_MOTIVATION[_etape % DEMO_MOTIVATION.size()]
	_fiche_ennemi.definir_motivation(reste, 28)
	_boite.afficher([
		"Thigoat utilise %s." % String(id).capitalize(),
		"C'est très efficace !",
	])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().reload_current_scene()
