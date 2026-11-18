extends Control
## Combat 1 contre 1 au tour par tour.
## Le joueur choisit : attaquer, utiliser un objet, changer de Gone ou fuir.
## L'ordre du tour dépend de la vitesse.

signal _touche_pressee

enum Mode { MESSAGE, MENU }

const OPTIONS_RACINE := ["Attaquer", "Objet", "Changer", "Fuir"]

var _ennemi: GoneInstance
var _actif: GoneInstance

var _mode: Mode = Mode.MESSAGE
var _contexte: StringName = &"racine"
var _options: Array = []
var _index: int = 0
var _attente_touche: bool = false
var _fini: bool = false
## Bonus temporaires accordés pendant le combat, remis à zéro à la fin.
var _modificateurs: Array = []

@onready var _ennemi_nom: Label = %EnnemiNom
@onready var _ennemi_pv: Label = %EnnemiPv
@onready var _joueur_nom: Label = %JoueurNom
@onready var _joueur_pv: Label = %JoueurPv
@onready var _ennemi_sprite: ColorRect = %EnnemiSprite
@onready var _joueur_sprite: ColorRect = %JoueurSprite
@onready var _journal: Label = %Journal
@onready var _menu: Label = %Menu

func _ready() -> void:
	GameState.assurer_partie()
	var fiche: GoneData = GameState.rencontre_en_attente
	if fiche == null:
		var sauvages := GameState.gones_sauvages()
		if sauvages.is_empty():
			_quitter("Aucun Gone disponible : vérifier data/gones.")
			return
		fiche = sauvages[0]
	_ennemi = GoneInstance.new(fiche, GameState.niveau_rencontre)
	_actif = GameState.premier_gone_valide()
	if _actif == null:
		_quitter("Votre équipe est hors de combat.")
		return
	_rafraichir()
	if GameState.combat_est_boss:
		await _dire("%s vous barre la route !" % _ennemi.nom())
	else:
		await _dire("%s cherche une alternance !" % _ennemi.nom())
	_menu_racine()

# =============================================================================
# Affichage
# =============================================================================
func _rafraichir() -> void:
	_ennemi_nom.text = "%s  Niv.%d" % [_ennemi.nom(), _ennemi.niveau]
	_ennemi_pv.text = "Motivation %d/%d  %s" % [_ennemi.pv, _ennemi.pv_max(), _barre(_ennemi)]
	_joueur_nom.text = "%s  Niv.%d" % [_actif.nom(), _actif.niveau]
	_joueur_pv.text = "Motivation %d/%d  %s" % [_actif.pv, _actif.pv_max(), _barre(_actif)]
	if _ennemi.data != null:
		_ennemi_sprite.color = _ennemi.data.couleur
	if _actif.data != null:
		_joueur_sprite.color = _actif.data.couleur

func _barre(g: GoneInstance) -> String:
	var plein := int(round(10.0 * float(g.pv) / float(maxi(1, g.pv_max()))))
	return "[%s%s]" % ["=".repeat(plein), ".".repeat(10 - plein)]

func _dire(texte: String) -> void:
	_mode = Mode.MESSAGE
	_journal.text = texte
	_menu.text = "\nEntrée pour continuer"
	_attente_touche = true
	await _touche_pressee
	_attente_touche = false

func _afficher_menu(contexte: StringName, invite: String, options: Array) -> void:
	_contexte = contexte
	_options = options
	_index = 0
	_mode = Mode.MENU
	_journal.text = invite
	_rafraichir_menu()

func _rafraichir_menu() -> void:
	var lignes: Array = []
	for i in _options.size():
		lignes.append(("> %s" % _options[i]) if i == _index else ("  %s" % _options[i]))
	_menu.text = "\n".join(lignes)

# =============================================================================
# Entrées
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if _fini:
		return
	if _attente_touche:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_touche_pressee.emit()
		return
	if _mode != Mode.MENU:
		return
	if event.is_action_pressed("ui_down"):
		_index = (_index + 1) % _options.size()
		_rafraichir_menu()
	elif event.is_action_pressed("ui_up"):
		_index = (_index - 1 + _options.size()) % _options.size()
		_rafraichir_menu()
	elif event.is_action_pressed("ui_cancel") and _contexte != &"racine":
		_menu_racine()
	elif event.is_action_pressed("ui_accept"):
		_valider()

# =============================================================================
# Menus
# =============================================================================
func _menu_racine() -> void:
	_afficher_menu(&"racine", "Que fait %s ?" % _actif.nom(), OPTIONS_RACINE.duplicate())

func _valider() -> void:
	match _contexte:
		&"racine":
			_choisir_action()
		&"attaques":
			var attaques := _actif.attaques()
			if _index < attaques.size():
				_tour_complet(attaques[_index])
			else:
				_menu_racine()
		&"objets":
			var objets := GameState.objets_possedes()
			if _index < objets.size():
				_utiliser_objet(objets[_index])
			else:
				_menu_racine()
		&"changer":
			if _index < GameState.equipe.size():
				_changer_de_gone(_index)
			else:
				_menu_racine()

func _choisir_action() -> void:
	match _index:
		0:
			var noms: Array = []
			for m in _actif.attaques():
				noms.append("%s (%d)" % [m.display_name, m.puissance])
			noms.append("Retour")
			_afficher_menu(&"attaques", "Quelle attaque ?", noms)
		1:
			var objets := GameState.objets_possedes()
			if objets.is_empty():
				_journal.text = "Le sac est vide."
				return
			var noms2: Array = []
			for o in objets:
				noms2.append("%s x%d" % [o.display_name, GameState.quantite_objet(o.id)])
			noms2.append("Retour")
			_afficher_menu(&"objets", "Quel objet ?", noms2)
		2:
			var noms3: Array = []
			for g in GameState.equipe:
				noms3.append("%s  PV %d/%d%s" % [g.nom(), g.pv, g.pv_max(), " (KO)" if g.est_ko() else ""])
			noms3.append("Retour")
			_afficher_menu(&"changer", "Envoyer qui ?", noms3)
		3:
			_fuir()

# =============================================================================
# Déroulement d'un tour
# =============================================================================
func _tour_complet(attaque: MoveData) -> void:
	_mode = Mode.MESSAGE
	if _actif.vitesse() >= _ennemi.vitesse():
		await _executer(_actif, _ennemi, attaque)
		if not _ennemi.est_ko():
			await _tour_ennemi()
	else:
		await _tour_ennemi()
		if not _actif.est_ko():
			await _executer(_actif, _ennemi, attaque)
	await _apres_tour()

func _tour_ennemi() -> void:
	var attaques := _ennemi.attaques()
	if attaques.is_empty():
		return
	await _executer(_ennemi, _actif, attaques[randi() % attaques.size()])

func _executer(attaquant: GoneInstance, cible: GoneInstance, attaque: MoveData) -> void:
	await _dire("%s utilise %s !" % [attaquant.nom(), attaque.display_name])
	if randi() % 100 >= attaque.precision:
		await _dire("Raté !")
		return
	if attaque.cible == MoveData.Cible.SOI:
		if attaque.soin > 0:
			attaquant.soigner(attaque.soin)
			await _dire("%s récupère %d PV." % [attaquant.nom(), attaque.soin])
	elif attaque.puissance > 0:
		var affinite := Affinites.multiplicateur(attaque.type, cible.data.type)
		var degats := _degats(attaquant, cible, attaque, affinite)
		cible.subir(degats)
		_rafraichir()
		var commentaire := Affinites.commentaire(affinite)
		await _dire("%d de Motivation en moins.%s" % [degats, "  " + commentaire if commentaire != "" else ""])
	if attaque.stat_modifiee != &"" and attaque.modificateur != 0:
		var beneficiaire := attaquant if attaque.cible == MoveData.Cible.SOI else cible
		_appliquer_modificateur(beneficiaire, attaque.stat_modifiee, attaque.modificateur * 2)
		await _dire("%s : %s %s." % [
			beneficiaire.nom(),
			attaque.stat_modifiee,
			"en hausse" if attaque.modificateur > 0 else "en baisse",
		])
	_rafraichir()

func _degats(attaquant: GoneInstance, cible: GoneInstance, attaque: MoveData,
		affinite: float = Affinites.NORMAL) -> int:
	var base := float(attaque.puissance) * float(attaquant.attaque()) / float(maxi(1, cible.defense()))
	return maxi(1, int(base * affinite * randf_range(0.85, 1.0)))

func _appliquer_modificateur(sur: GoneInstance, stat: StringName, valeur: int) -> void:
	sur.appliquer_entrainement(stat, valeur)
	_modificateurs.append({"gone": sur, "stat": stat, "valeur": valeur})

func _retirer_modificateurs() -> void:
	for m in _modificateurs:
		m["gone"].appliquer_entrainement(m["stat"], -int(m["valeur"]))
	_modificateurs.clear()

func _apres_tour() -> void:
	_rafraichir()
	if _ennemi.est_ko():
		await _victoire()
		return
	if _actif.est_ko():
		await _dire("%s est hors de combat !" % _actif.nom())
		var suivant := GameState.premier_gone_valide()
		if suivant == null:
			await _defaite()
			return
		_actif = suivant
		_rafraichir()
		await _dire("En avant, %s !" % _actif.nom())
	_menu_racine()

# =============================================================================
# Objets, changement, fuite
# =============================================================================
func _utiliser_objet(objet: ItemData) -> void:
	_mode = Mode.MESSAGE
	match objet.genre:
		ItemData.Genre.SOIN:
			GameState.consommer_objet(objet.id)
			_actif.soigner(objet.valeur)
			_rafraichir()
			await _dire("%s rend %d PV à %s." % [objet.display_name, objet.valeur, _actif.nom()])
			await _tour_ennemi()
			await _apres_tour()
		ItemData.Genre.CAPTURE:
			await _tenter_capture(objet)
		_:
			await _dire("Rien ne se passe.")
			_menu_racine()

func _tenter_capture(objet: ItemData) -> void:
	if GameState.combat_est_boss:
		await _dire("On ne recrute pas le directeur comme ça.")
		_menu_racine()
		return
	if GameState.equipe_est_pleine():
		await _dire("L'équipe est déjà complète (%d alternants)." % GameState.TAILLE_EQUIPE_MAX)
		_menu_racine()
		return
	GameState.consommer_objet(objet.id)
	await _dire("Vous tendez un %s..." % objet.display_name)
	var part_pv := float(_ennemi.pv) / float(maxi(1, _ennemi.pv_max()))
	var chance := int(_ennemi.data.taux_capture * (1.0 - 0.7 * part_pv) + objet.valeur * 0.5)
	chance = clampi(chance, 5, 95)
	if randi() % 100 < chance:
		_retirer_modificateurs()
		_ennemi.soigner_tout()
		GameState.ajouter_a_equipe(_ennemi)
		if GameState.pnj_en_combat != &"":
			GameState.lever_drapeau(GameState.pnj_en_combat)
		await _dire("%s signe ! Il rejoint l'équipe." % _ennemi.nom())
		_quitter("%s a rejoint l'équipe." % _ennemi.nom())
	else:
		await _dire("Il relit les clauses… et refuse de signer.")
		await _tour_ennemi()
		await _apres_tour()

func _changer_de_gone(index: int) -> void:
	var cible: GoneInstance = GameState.equipe[index]
	if cible == _actif:
		_journal.text = "%s est déjà au combat." % cible.nom()
		return
	if cible.est_ko():
		_journal.text = "%s est hors de combat." % cible.nom()
		return
	_mode = Mode.MESSAGE
	_actif = cible
	_rafraichir()
	await _dire("En avant, %s !" % _actif.nom())
	await _tour_ennemi()
	await _apres_tour()

func _fuir() -> void:
	_mode = Mode.MESSAGE
	if GameState.combat_est_boss:
		await _dire("Impossible de fuir ce combat.")
		_menu_racine()
		return
	var chance := 50 + (_actif.vitesse() - _ennemi.vitesse()) * 5
	if randi() % 100 < clampi(chance, 20, 95):
		await _dire("Vous prenez la fuite.")
		_quitter("Vous avez pris la fuite.")
	else:
		await _dire("Fuite ratée !")
		await _tour_ennemi()
		await _apres_tour()

# =============================================================================
# Fin de combat
# =============================================================================
func _victoire() -> void:
	await _dire("%s est hors de combat !" % _ennemi.nom())
	if _actif.niveau < _ennemi.niveau + 3:
		_actif.niveau += 1
		_actif.soigner(2)
		await _dire("%s passe au niveau %d !" % [_actif.nom(), _actif.niveau])
	if GameState.combat_est_boss:
		GameState.lever_drapeau(&"gardien_battu")
		await _dire("La pointe est à vous. Fin du MVP : merci d'avoir joué.")
		_quitter("Vous avez battu le gardien du confluent.")
		return
	_quitter("%s a été battu." % _ennemi.nom())

func _defaite() -> void:
	await _dire("Toute l'équipe est hors de combat...")
	GameState.soigner_equipe()
	GameState.zone_courante = &"perrache"
	GameState.case_joueur = Zones.zone(&"perrache")["depart"]
	_quitter("Vous vous réveillez à Perrache, l'équipe soignée.")

func _quitter(message: String) -> void:
	if _fini:
		return
	_fini = true
	_retirer_modificateurs()
	GameState.rencontre_en_attente = null
	GameState.combat_est_boss = false
	GameState.pnj_en_combat = &""
	GameState.dernier_resultat_combat = message
	GameState.sauvegarde_auto()
	GameState.equipe_modifiee.emit()
	get_tree().change_scene_to_file(GameState.SCENE_MONDE)
