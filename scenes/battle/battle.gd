extends Control
## Combat 1 contre 1 au tour par tour.
## Le joueur choisit : attaquer, utiliser un objet, changer de Gone ou fuir.
## L'ordre du tour dépend de la vitesse.

## L'écran parle, ou le joueur choisit. Les fonctions de règles posent MESSAGE
## avant d'enchaîner des `await _dire()` ; l'affichage suit dans _dire() et
## _afficher_menu().
enum Mode { MESSAGE, MENU }

const OPTIONS_RACINE := ["Attaquer", "Objet", "Changer", "Fuir"]

var _ennemi: GoneInstance
var _actif: GoneInstance

var _mode: Mode = Mode.MESSAGE
var _contexte: StringName = &"racine"
var _options: Array = []
var _index: int = 0
var _fini: bool = false
## Bonus temporaires accordés pendant le combat, remis à zéro à la fin.
var _modificateurs: Array = []
## Les attaques proposees au tour en cours, dans l'ordre du menu.
var _attaques_offertes: Array = []
## Ce que rapporte un tour sans attaquer : objet, changement, defense.
const CAFE_PAR_TOUR_SANS_ATTAQUE := 2

## Largeurs du bas de l'écran, en pixels (l'écran fait 320 de large).
## Le menu principal tient à droite de la boîte ; les sous-menus ont des
## libellés longs (« Lancer de sauce curry »), ils mordent sur sa largeur ;
## pendant un message, la boîte prend tout.
const MENU_X_RACINE := 200.0
const MENU_X_SOUS_MENU := 120.0
const BOITE_LARGEUR_RACINE := 192.0
const BOITE_LARGEUR_SOUS_MENU := 112.0
const BOITE_LARGEUR_MESSAGE := 308.0

@onready var _fiche_ennemi: FicheCombattant = %FicheEnnemi
@onready var _fiche_joueur: FicheCombattant = %FicheJoueur
@onready var _ennemi_sprite: ColorRect = %EnnemiSprite
@onready var _joueur_sprite: ColorRect = %JoueurSprite
@onready var _portrait_ennemi: TextureRect = %PortraitEnnemi
@onready var _portrait_joueur: TextureRect = %PortraitJoueur
@onready var _boite: BoiteDialogue = %Boite
@onready var _menu: ListeMenu = %Menu

func _ready() -> void:
	_menu.choix_valide.connect(_sur_choix)
	_menu.choix_change.connect(_sur_survol)
	_menu.annule.connect(_sur_annulation)
	GameState.assurer_partie()
	GameState.jouer_musique(&"combat")
	# Le brouhaha de la gare reste sur la carte : le combat se joue ailleurs.
	GameState.arreter_ambiance()
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
	# Envoyer quelqu'un au combat a bout de forces, ca se paie aussi.
	if float(_actif.pv) / float(maxi(1, _actif.pv_max())) < 0.25:
		GameState.ajuster_bienveillance(-1, "alternant envoyé épuisé")
	if GameState.combat_est_boss:
		await _dire("%s vous barre la route !" % _ennemi.nom())
	else:
		await _dire("%s cherche une alternance !" % _ennemi.nom())
	_menu_racine()

# =============================================================================
# Affichage
# =============================================================================
func _rafraichir() -> void:
	_fiche_ennemi.definir_combattant(_ennemi.nom(), _ennemi.niveau, _type_de(_ennemi))
	_fiche_ennemi.definir_motivation(_ennemi.pv, _ennemi.pv_max())
	_fiche_joueur.definir_combattant(_actif.nom(), _actif.niveau, _type_de(_actif))
	_fiche_joueur.definir_motivation(_actif.pv, _actif.pv_max())
	_fiche_joueur.definir_cafe(_actif.cafe, _actif.cafe_max())
	_poser_portrait(_portrait_ennemi, _ennemi_sprite, _ennemi, &"idle_down")
	_poser_portrait(_portrait_joueur, _joueur_sprite, _actif, &"idle_up")

## Affiche l'alternant : son image s'il a une planche, sinon sa couleur.
## L'adversaire est vu de face, celui du joueur de dos, comme il se doit.
func _poser_portrait(portrait: TextureRect, fond: ColorRect,
		alternant: GoneInstance, animation: StringName) -> void:
	var planche: SpriteFrames = alternant.data.frames if alternant.data != null else null
	if planche != null and planche.has_animation(animation) \
			and planche.get_frame_count(animation) > 0:
		_afficher_image(portrait, fond, planche.get_frame_texture(animation, 0))
		portrait.flip_h = false
		portrait.visible = true
		fond.color = Color(0, 0, 0, 0)
		return
	portrait.visible = false
	if alternant.data != null:
		fond.color = alternant.data.couleur

## Cale l'image sur la hauteur du cadre, centree : les cases de combat sont plus
## larges (jambe tendue) et ne doivent pas rapetisser le personnage.
func _afficher_image(portrait: TextureRect, fond: ColorRect, image: Texture2D) -> void:
	portrait.texture = image
	portrait.stretch_mode = TextureRect.STRETCH_SCALE
	portrait.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var echelle: float = fond.size.y / maxf(image.get_height(), 1.0)
	portrait.size = Vector2(image.get_width(), image.get_height()) * echelle
	portrait.position = Vector2((fond.size.x - portrait.size.x) / 2.0, 0.0)

## Joue une animation de combat (combat_poing, combat_pied, combat_touche) sur
## l'image d'un alternant, puis le remet dans sa pose. Les poses de combat sont de
## profil, tournees vers la droite : l'adversaire, en haut a droite, est retourne.
func _jouer_combat(alternant: GoneInstance, animation: StringName) -> void:
	var planche: SpriteFrames = alternant.data.frames if alternant.data != null else null
	if planche == null or not planche.has_animation(animation):
		return
	var portrait := _portrait_ennemi if alternant == _ennemi else _portrait_joueur
	var fond := _ennemi_sprite if alternant == _ennemi else _joueur_sprite
	var duree := 1.0 / maxf(planche.get_animation_speed(animation), 1.0)
	portrait.flip_h = alternant == _ennemi
	for i in planche.get_frame_count(animation):
		_afficher_image(portrait, fond, planche.get_frame_texture(animation, i))
		await get_tree().create_timer(duree).timeout
	_rafraichir()

func _type_de(g: GoneInstance) -> StringName:
	return g.data.type if g.data != null else &"neutre"

## Une ligne de texte, puis on attend que le joueur valide. Le menu s'efface
## pendant ce temps : le clavier appartient à la boîte de dialogue.
func _dire(texte: String) -> void:
	_mode = Mode.MESSAGE
	_menu.visible = false
	_menu.interactif = false
	_boite.offset_right = _boite.offset_left + BOITE_LARGEUR_MESSAGE
	await _boite.afficher(texte)

## Pose une question et la liste des réponses. `colonnes` à 2 pour le menu
## principal, en grille comme dans un Pokémon.
func _afficher_menu(contexte: StringName, invite: String, options: Array,
		colonnes: int = 1) -> void:
	_contexte = contexte
	_options = options
	_index = 0
	_mode = Mode.MENU
	var racine := colonnes > 1
	_menu.offset_left = MENU_X_RACINE if racine else MENU_X_SOUS_MENU
	_boite.offset_right = _boite.offset_left + (
		BOITE_LARGEUR_RACINE if racine else BOITE_LARGEUR_SOUS_MENU)
	_boite.afficher_invite(invite)
	_menu.colonnes = colonnes
	_menu.definir_options(options)
	_menu.visible = true
	_menu.interactif = true

# =============================================================================
# Entrées
# =============================================================================
## Le joueur a validé une option. On retrouve l'index choisi : les règles
## derrière (_valider) n'ont pas changé.
func _sur_choix(index: int, _id: StringName) -> void:
	if _fini:
		return
	_index = index
	_valider()

## Le curseur a bougé. Dans le menu des attaques, la boîte détaille celle qui
## est sous le curseur.
func _sur_survol(index: int, _id: StringName) -> void:
	if _contexte != &"attaques" or index >= _attaques_offertes.size():
		return
	var attaque: MoveData = _attaques_offertes[index]
	var effet := "%d dégâts" % attaque.puissance if attaque.puissance > 0 else "soutien"
	_boite.afficher_invite("%s — %s, type %s." % [
		attaque.display_name, effet, PaletteUi.libelle_type(attaque.type)])

## Échap dans un sous-menu : retour au menu principal.
func _sur_annulation() -> void:
	if _fini or _contexte == &"racine":
		return
	_menu_racine()

# =============================================================================
# Menus
# =============================================================================
func _menu_racine() -> void:
	_afficher_menu(&"racine", "Que fait %s ?" % _actif.nom(), OPTIONS_RACINE.duplicate(), 2)

func _valider() -> void:
	match _contexte:
		&"racine":
			_choisir_action()
		&"attaques":
			if _index < _attaques_offertes.size():
				_tour_complet(_attaques_offertes[_index])
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
			_attaques_offertes = _attaques_possibles(_actif)
			var noms: Array = []
			for m: MoveData in _attaques_offertes:
				var cout := m.cout_cafe()
				noms.append({
					"id": m.id,
					"texte": m.display_name,
					"detail": "gratuit" if cout == 0 else "%d café" % cout,
				})
			noms.append({"id": &"retour", "texte": "Retour"})
			_afficher_menu(&"attaques", "Quelle attaque ?", noms)
		1:
			var objets := GameState.objets_possedes()
			if objets.is_empty():
				_boite.afficher_invite("Le sac est vide.")
				return
			var noms2: Array = []
			for o in objets:
				noms2.append({
					"id": o.id,
					"texte": o.display_name,
					"detail": "x%d" % GameState.quantite_objet(o.id),
				})
			noms2.append({"id": &"retour", "texte": "Retour"})
			_afficher_menu(&"objets", "Quel objet ?", noms2)
		2:
			var noms3: Array = []
			for g: GoneInstance in GameState.equipe:
				noms3.append({
					"id": StringName(g.nom()),
					"texte": g.nom(),
					"detail": "KO" if g.est_ko() else "%d/%d" % [g.pv, g.pv_max()],
					"actif": not g.est_ko() and g != _actif,
				})
			noms3.append({"id": &"retour", "texte": "Retour"})
			_afficher_menu(&"changer", "Envoyer qui ?", noms3)
		3:
			_fuir()

# =============================================================================
# Déroulement d'un tour
# =============================================================================
func _tour_complet(attaque: MoveData) -> void:
	_mode = Mode.MESSAGE
	if _actif.vitesse() >= _ennemi.vitesse():
		await _agir(_actif, _ennemi, attaque)
		if not _ennemi.est_ko():
			await _tour_ennemi()
	else:
		await _tour_ennemi()
		if not _actif.est_ko():
			await _agir(_actif, _ennemi, attaque)
	await _fin_de_tour()
	await _apres_tour()

## Un alternant etourdi passe son tour : c'est la seule chose qui l'empeche
## d'agir, et ca lui coute son attaque, pas seulement ses degats.
func _agir(attaquant: GoneInstance, cible: GoneInstance, attaque: MoveData) -> void:
	if attaquant.est_etourdi():
		await _dire("%s est sonné : il passe son tour." % attaquant.nom())
		return
	await _executer(attaquant, cible, attaque)

## Fin de tour : les brulures mordent, les recharges s'egrenent.
func _fin_de_tour() -> void:
	for combattant: GoneInstance in [_actif, _ennemi]:
		var degats := combattant.consumer_etat()
		if degats > 0:
			_rafraichir()
			await _dire("%s perd %d de Motivation : il brûle encore."
				% [combattant.nom(), degats])
		combattant.egrener_recharges()
	_rafraichir()

func _tour_ennemi() -> void:
	if _ennemi.est_etourdi():
		await _dire("%s est sonné : il passe son tour." % _ennemi.nom())
		return
	var attaques := _attaques_possibles(_ennemi)
	if attaques.is_empty():
		return
	await _executer(_ennemi, _actif, attaques[randi() % attaques.size()])

func _executer(attaquant: GoneInstance, cible: GoneInstance, attaque: MoveData) -> void:
	attaquant.depenser_cafe(attaque.cout_cafe())
	_rafraichir()
	await _dire("%s utilise %s !" % [attaquant.nom(), attaque.display_name])
	if randi() % 100 >= attaque.precision:
		await _dire("Raté !")
		return
	if attaque.cible == MoveData.Cible.SOI:
		if attaque.soin > 0:
			attaquant.soigner(attaque.soin)
			await _dire("%s récupère %d PV." % [attaquant.nom(), attaque.soin])
	elif attaque.puissance > 0 or attaque.degats_max > 0:
		var affinite := Affinites.multiplicateur(attaque.type, cible.data.type)
		var degats := _degats(attaquant, cible, attaque, affinite)
		var critique := attaque.chance_critique > 0 and randi() % 100 < attaque.chance_critique
		if critique:
			degats = int(degats * 1.5)
		await _jouer_combat(attaquant, &"combat_pied" if randi() % 2 == 0 else &"combat_poing")
		GameState.jouer_son(&"attaque")
		cible.subir(degats)
		_rafraichir()
		await _jouer_combat(cible, &"combat_touche")
		var commentaire := Affinites.commentaire(affinite)
		if critique:
			commentaire = "Coup critique ! " + commentaire
		await _dire("%d de Motivation en moins.%s" % [degats, "  " + commentaire if commentaire != "" else ""])
	# L'etat pose, s'il y en a un. Un nouvel etat remplace le precedent.
	if attaque.etourdit:
		cible.appliquer_etat(GoneInstance.ETAT_ETOURDI, 1)
		await _dire("%s ne sait plus où il habite." % cible.nom())
	elif attaque.brulure_tours > 0:
		cible.appliquer_etat(GoneInstance.ETAT_BRULURE, attaque.brulure_tours,
			attaque.brulure_degats)
		await _dire("%s est en feu pour %d tours." % [cible.nom(), attaque.brulure_tours])
	# Ce que l'attaque coute a celui qui la lance.
	if attaque.cout_pv > 0:
		attaquant.subir(attaque.cout_pv)
		_rafraichir()
		await _dire("%s s'inflige %d de Motivation au passage." % [attaquant.nom(), attaque.cout_pv])
	attaquant.lancer_recharge(attaque)
	if attaque.stat_modifiee != &"" and attaque.modificateur != 0:
		var beneficiaire := attaquant if attaque.cible == MoveData.Cible.SOI else cible
		_appliquer_modificateur(beneficiaire, attaque.stat_modifiee, attaque.modificateur * 2)
		await _dire("%s : %s %s." % [
			beneficiaire.nom(),
			attaque.stat_modifiee,
			"en hausse" if attaque.modificateur > 0 else "en baisse",
		])
	_rafraichir()

## Les attaques qu'un alternant peut encore se payer. A sec, il ne lui reste
## que "Trainer des pieds" : il n'est jamais bloque, seulement diminue.
func _attaques_possibles(alternant: GoneInstance) -> Array:
	var possibles: Array = []
	for m: MoveData in alternant.attaques():
		if alternant.peut_lancer(m):
			possibles.append(m)
	if possibles.is_empty():
		var repli: MoveData = GameState.catalogue_attaques.get(&"trainer_des_pieds")
		if repli != null:
			possibles.append(repli)
	return possibles

func _degats(attaquant: GoneInstance, cible: GoneInstance, attaque: MoveData,
		affinite: float = Affinites.NORMAL) -> int:
	# Une attaque a degats aleatoires ignore la puissance, la Competence et la
	# Defense : c'est tout son interet, elle est imprevisible.
	if attaque.degats_max > 0:
		return maxi(1, int(randi_range(attaque.degats_min, attaque.degats_max) * affinite))
	var base := float(attaque.puissance) * float(attaquant.attaque()) / float(maxi(1, cible.defense()))
	return maxi(1, int(base * affinite * randf_range(0.85, 1.0)))

func _appliquer_modificateur(sur: GoneInstance, stat: StringName, valeur: int) -> void:
	sur.modifier_stat(stat, valeur)
	_modificateurs.append({"gone": sur, "stat": stat, "valeur": valeur})

func _retirer_modificateurs() -> void:
	for m in _modificateurs:
		m["gone"].modifier_stat(m["stat"], -int(m["valeur"]))
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
			_actif.recuperer_cafe(CAFE_PAR_TOUR_SANS_ATTAQUE)
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
	# Un contrat plus genereux que le minimum, ca se remarque.
	if objet.valeur > 30:
		GameState.ajuster_bienveillance(2, "contrat généreux")
	await _dire("Vous tendez un %s..." % objet.display_name)
	var part_pv := float(_ennemi.pv) / float(maxi(1, _ennemi.pv_max()))
	var chance := int((_ennemi.data.taux_capture * (1.0 - 0.7 * part_pv) + objet.valeur * 0.5)
		* GameState.bonus_recrutement())
	chance = clampi(chance, 5, 95)
	if randi() % 100 < chance:
		_retirer_modificateurs()
		_ennemi.soigner_tout()
		GameState.ajouter_a_equipe(_ennemi)
		if GameState.pnj_en_combat != &"":
			GameState.lever_drapeau(GameState.pnj_en_combat)
		GameState.jouer_son(&"niveau_gagne")
		await _dire("%s signe ! Il rejoint l'équipe." % _ennemi.nom())
		_quitter("%s a rejoint l'équipe." % _ennemi.nom())
	else:
		await _dire("Il relit les clauses… et refuse de signer.")
		await _tour_ennemi()
		await _apres_tour()

func _changer_de_gone(index: int) -> void:
	var cible: GoneInstance = GameState.equipe[index]
	if cible == _actif:
		_boite.afficher_invite("%s est déjà au combat." % cible.nom())
		return
	if cible.est_ko():
		_boite.afficher_invite("%s est hors de combat." % cible.nom())
		return
	_mode = Mode.MESSAGE
	_actif = cible
	_actif.recuperer_cafe(CAFE_PAR_TOUR_SANS_ATTAQUE)
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
	# La musique de combat s'efface : le jingle de victoire joue seul, et la
	# carte relancera l'exploration en reprenant la main.
	GameState.arreter_musique()
	GameState.jouer_son(&"victoire")
	await _dire("%s est hors de combat !" % _ennemi.nom())
	if _actif.niveau < _ennemi.niveau + GameState.marge_de_niveau():
		var stade_avant := _actif.stade()
		_actif.niveau += 1
		_actif.soigner(2)
		GameState.jouer_son(&"niveau_gagne")
		await _dire("%s passe au niveau %d !" % [_actif.nom(), _actif.niveau])
		if _actif.stade() > stade_avant:
			_actif.soigner_tout()
			_rafraichir()
			GameState.jouer_son(&"niveau_gagne")
			await _dire("%s finit son année : il devient %s !"
				% [_actif.nom(), _actif.nom_du_stade()])
	if GameState.combat_est_boss:
		GameState.lever_drapeau(&"gardien_battu")
		for combattant: GoneInstance in GameState.equipe:
			combattant.oublier_les_etats()
		GameState.sauvegarde_auto()
		get_tree().change_scene_to_file(GameState.SCENE_FIN)
		return
		await _dire("L'EEMI est à vous. Fin du MVP : merci d'avoir joué.")
		_quitter("Vous avez battu le gardien du confluent.")
		return
	_quitter("%s a été battu." % _ennemi.nom())

func _defaite() -> void:
	GameState.arreter_musique()
	GameState.jouer_son(&"defaite")
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
	for combattant: GoneInstance in GameState.equipe:
		combattant.oublier_les_etats()
	GameState.rencontre_en_attente = null
	GameState.combat_est_boss = false
	GameState.pnj_en_combat = &""
	GameState.dernier_resultat_combat = message
	GameState.sauvegarde_auto()
	GameState.equipe_modifiee.emit()
	get_tree().change_scene_to_file(GameState.SCENE_MONDE)
