extends Node2D
## La carte. Deux TileMapLayer construites depuis les plans texte de zones.gd :
## une couche de sol, et une couche de decor triee en profondeur (Y-sort), pour
## que le joueur passe derriere ce qui est devant lui.
##
## Quand l'equipe aura dessine les vraies tuiles, il suffira de remplacer le PNG
## du tileset : les plans et le code ne bougent pas.

enum Mode { LIBRE, MENU }

const CHANCE_RENCONTRE := 0.14
const SCENE_PNJ: PackedScene = preload("res://scenes/world/pnj.tscn")
## Chance qu'un PNJ se contente de tourner la tete au lieu de faire un pas.
const CHANCE_PNJ_REGARDE := 0.3

## action -> [deplacement, Joueur.Direction]. Les entiers suivent l'ordre de
## l'enum Direction de player.gd : BAS, HAUT, GAUCHE, DROITE.
const DIRECTIONS := {
	"ui_down": [Vector2i(0, 1), 0],
	"ui_up": [Vector2i(0, -1), 1],
	"ui_left": [Vector2i(-1, 0), 2],
	"ui_right": [Vector2i(1, 0), 3],
}

var zone_id: StringName = &"perrache"
var zone: Dictionary = {}

var _mode: Mode = Mode.LIBRE
var _menu_contexte: StringName = &""
var _menu_titre: String = ""
var _menu_options: Array = []
var _menu_index: int = 0
var _minijeu_choisi: StringName = &""

@onready var _sol: TileMapLayer = %Sol
@onready var _decor: TileMapLayer = %Decor
@onready var _joueur: Joueur = %Joueur
@onready var _pnjs: Node2D = %Pnjs
@onready var _label_zone: Label = %Zone
@onready var _label_message: Label = %Message
@onready var _volet: ColorRect = %Volet
@onready var _overlay: Label = %Overlay

func _ready() -> void:
	GameState.assurer_partie()
	_joueur.deplacement_fini.connect(_sur_case_atteinte)
	_charger_zone(GameState.zone_courante, GameState.case_joueur)
	if GameState.dernier_resultat_combat != "":
		_message(GameState.dernier_resultat_combat)
		GameState.dernier_resultat_combat = ""
	else:
		_message("Flèches : marcher     Entrée : agir     Échap : menu")

# =============================================================================
# Construction de la carte
# =============================================================================
func _charger_zone(id: StringName, case_depart: Vector2i) -> void:
	zone_id = id
	zone = Zones.zone(id)
	GameState.zone_courante = id

	# Une sauvegarde ancienne peut pointer hors de la zone : on retombe au depart.
	var depart: Vector2i = case_depart
	if not Zones.est_traversable(id, depart):
		depart = zone["depart"]
	GameState.case_joueur = depart

	_peindre_zone()
	_placer_pnj()
	_joueur.placer(depart)
	_joueur.borner_camera(Zones.taille_pixels(id))
	_label_zone.text = str(zone["titre"])

## Une entree de table vaut [source, case de l'atlas].
func _poser(couche: TileMapLayer, cellule: Vector2i, entree: Array) -> void:
	couche.set_cell(cellule, int(entree[0]), entree[1])

func _peindre_zone() -> void:
	_sol.clear()
	_decor.clear()
	var plan: Array = zone["plan"]
	for y in plan.size():
		var ligne: String = plan[y]
		for x in ligne.length():
			var c: String = ligne[x]
			var cellule := Vector2i(x, y)
			if Zones.SOLS.has(c):
				_poser(_sol, cellule, Zones.sol_de(c, cellule))
			if c == "R":
				_decor.set_cell(cellule, Zones.IMPORT, zone["tuile_ressource"])
			elif Zones.DECORS.has(c):
				_poser(_decor, cellule, Zones.DECORS[c])
	# Deuxieme passe : la partie haute des volumes deborde sur la case du dessus.
	for y in plan.size():
		var ligne2: String = plan[y]
		for x in ligne2.length():
			var c2: String = ligne2[x]
			if not Zones.DECORS_HAUT.has(c2) or y == 0:
				continue
			var dessus := Vector2i(x, y - 1)
			if Zones.case_a(zone_id, dessus) == c2:
				continue          # un autre bloc du meme volume : rien a coiffer
			_poser(_decor, dessus, Zones.DECORS_HAUT[c2])

# =============================================================================
# Deplacement
# =============================================================================
func _process(_delta: float) -> void:
	# Touche maintenue : on enchaine les pas tant qu'elle est enfoncee.
	if _mode != Mode.LIBRE or _joueur.en_mouvement:
		return
	for action in DIRECTIONS:
		if Input.is_action_pressed(action):
			_tenter_pas(action)
			return

## Un pas, ou un simple demi-tour si la case est bloquee.
func _tenter_pas(action: String) -> void:
	if _joueur.en_mouvement:
		return
	var consigne: Array = DIRECTIONS[action]
	var cible: Vector2i = _joueur.cellule + consigne[0]
	if Zones.est_traversable(zone_id, cible) and _pnj_sur(cible) == null:
		_joueur.avancer_vers(cible, consigne[1])
	else:
		_joueur.regarder(consigne[1])

func _sur_case_atteinte(cellule: Vector2i) -> void:
	GameState.case_joueur = cellule
	var c := _case_courante()
	var sorties: Dictionary = zone["sorties"]
	if sorties.has(c):
		var sortie: Array = sorties[c]
		_charger_zone(StringName(sortie[0]), Vector2i(int(sortie[1]), int(sortie[2])))
		_message("Vous arrivez : %s" % zone["titre"])
		GameState.sauvegarde_auto()
		return
	match c:
		"T":
			var sortie_traboule := Zones.autre_traboule(zone_id, cellule)
			_joueur.placer(sortie_traboule)
			GameState.case_joueur = sortie_traboule
			_message("Un passage sous les voies ferrées.")
		"R":
			_ramasser_ressource(cellule)
		"g":
			_tenter_rencontre()
		_:
			var indice := _indice_case(c)
			if indice != "":
				_message(indice)

func _case_courante() -> String:
	return Zones.case_a(zone_id, _joueur.cellule)

func _indice_case(c: String) -> String:
	match c:
		"S":
			return "Soins. Entrée pour remettre l'équipe d'aplomb."
		"B":
			return "Boutique. Entrée pour échanger des ressources."
		"M":
			return "Entraînement. Entrée pour lancer un mini-jeu."
		"X":
			return "Quelqu'un garde la pointe. Entrée pour l'affronter."
		_:
			return ""

# =============================================================================
# PNJ qui se baladent
# =============================================================================
func _placer_pnj() -> void:
	for ancien in _pnjs.get_children():
		ancien.queue_free()
	for fiche: Dictionary in zone.get("pnj", []):
		var pnj: Pnj = SCENE_PNJ.instantiate()
		pnj.name = str(fiche["nom"])
		pnj.sprite = load(str(fiche["sprite"]))
		_pnjs.add_child(pnj)
		pnj.placer(fiche["case"])
		pnj.envie_de_bouger.connect(_sur_envie_pnj)

## Le PNJ demande a bouger : la carte choisit une case libre autour de lui.
func _sur_envie_pnj(pnj: Pnj) -> void:
	if _mode != Mode.LIBRE:
		return
	var consigne: Array = DIRECTIONS.values().pick_random()
	var vers: Joueur.Direction = consigne[1]
	if randf() < CHANCE_PNJ_REGARDE:
		pnj.regarder(vers)
		return
	var cible: Vector2i = pnj.cellule + consigne[0]
	var ecart: Vector2i = (cible - pnj.case_depart).abs()
	if Zones.accepte_pnj(zone_id, cible) and _case_libre(cible) and maxi(ecart.x, ecart.y) <= pnj.rayon:
		pnj.avancer_vers(cible, vers)
	else:
		pnj.regarder(vers)

## Libre = ni le joueur (ou la case ou il va), ni un PNJ.
func _case_libre(c: Vector2i) -> bool:
	return c != _joueur.cellule and _pnj_sur(c) == null

func _pnj_sur(c: Vector2i) -> Pnj:
	for pnj: Pnj in _pnjs.get_children():
		if pnj.cellule == c and not pnj.is_queued_for_deletion():
			return pnj
	return null

# =============================================================================
# Ressources et rencontres
# =============================================================================
func _ramasser_ressource(cellule: Vector2i) -> void:
	var cle := StringName("ramasse_%s_%d_%d" % [zone_id, cellule.x, cellule.y])
	if GameState.drapeau(cle):
		return
	var ressource: StringName = zone["ressource"]
	GameState.lever_drapeau(cle)
	GameState.ajouter_ressource(ressource, 2)
	_decor.set_cell(cellule, -1)          # l'objet ramasse disparait
	_poser(_sol, cellule, Zones.SOLS["h"])
	_message("+2 %s (total : %d)" % [
		GameState.RESSOURCES.get(ressource, ressource),
		GameState.quantite_ressource(ressource),
	])

func _tenter_rencontre() -> void:
	if randf() > CHANCE_RENCONTRE:
		return
	var candidats: Array = []
	var sauvages := GameState.gones_sauvages()
	for id in zone["rencontres"]:
		var fiche: GoneData = GameState.catalogue_gones.get(id)
		if fiche != null and fiche in sauvages:
			candidats.append(fiche)
	if candidats.is_empty():
		candidats = sauvages
	if candidats.is_empty():
		return
	GameState.rencontre_en_attente = candidats[randi() % candidats.size()]
	GameState.niveau_rencontre = randi_range(int(zone["niveau_min"]), int(zone["niveau_max"]))
	GameState.combat_est_boss = false
	get_tree().change_scene_to_file(GameState.SCENE_COMBAT)

func _lancer_combat_de_fin() -> void:
	if GameState.drapeau(&"gardien_battu"):
		_message("La pointe est calme. Fin du MVP : merci d'avoir joué.")
		return
	var gardien: GoneData = GameState.catalogue_gones.get(&"generique_gardien_fourviere")
	if gardien == null:
		_message("Le gardien est introuvable (data/gones manquant).")
		return
	GameState.rencontre_en_attente = gardien
	GameState.niveau_rencontre = 12
	GameState.combat_est_boss = true
	get_tree().change_scene_to_file(GameState.SCENE_COMBAT)

# =============================================================================
# Interaction et menus
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if _mode == Mode.MENU:
		_input_menu(event)
		return
	if event.is_action_pressed("ui_cancel"):
		_ouvrir_menu(&"pause", "Menu", ["Équipe", "Sauvegarder", "Retour au titre", "Reprendre"])
		return
	if event.is_action_pressed("ui_accept"):
		_interagir()
		return
	# Une tape breve peut durer moins qu'une image : on la prend a l'evenement,
	# sinon le pas serait perdu. La touche maintenue, elle, passe par _process.
	for action in DIRECTIONS:
		if event.is_action_pressed(action):
			_tenter_pas(action)
			return

func _interagir() -> void:
	match _case_courante():
		"S":
			GameState.soigner_equipe()
			GameState.sauvegarde_auto()
			_message("Toute l'équipe est soignée.")
		"B":
			_ouvrir_menu(&"boutique", _texte_boutique(), [
				"3 pralines -> 1 Filet à Gone",
				"4 cocons -> 1 Barre de cocon",
				"Annuler",
			])
		"M":
			_ouvrir_menu(&"entrainement", "Quel entraînement ?", [
				"Rythme (vitesse)",
				"Frappe chronométrée (attaque)",
				"Annuler",
			])
		"X":
			_lancer_combat_de_fin()
		_:
			_message("Rien à faire ici.")

func _ouvrir_menu(contexte: StringName, titre: String, options: Array) -> void:
	_menu_contexte = contexte
	_menu_titre = titre
	_menu_options = options
	_menu_index = 0
	_mode = Mode.MENU
	_rafraichir_overlay()

func _fermer_menu() -> void:
	_mode = Mode.LIBRE
	_menu_contexte = &""
	_volet.visible = false
	_overlay.visible = false

func _rafraichir_overlay() -> void:
	var lignes: Array = [_menu_titre, ""]
	for i in _menu_options.size():
		lignes.append(("> %s" % _menu_options[i]) if i == _menu_index else ("  %s" % _menu_options[i]))
	_overlay.text = "\n".join(lignes)
	_volet.visible = true
	_overlay.visible = true

func _input_menu(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_menu_index = (_menu_index + 1) % _menu_options.size()
		_rafraichir_overlay()
	elif event.is_action_pressed("ui_up"):
		_menu_index = (_menu_index - 1 + _menu_options.size()) % _menu_options.size()
		_rafraichir_overlay()
	elif event.is_action_pressed("ui_cancel"):
		_fermer_menu()
	elif event.is_action_pressed("ui_accept"):
		_valider_menu()

func _valider_menu() -> void:
	var choix: String = str(_menu_options[_menu_index])
	if choix == "Annuler" or choix == "Fermer" or choix == "Reprendre":
		_fermer_menu()
		return
	match _menu_contexte:
		&"pause":
			_menu_pause(choix)
		&"boutique":
			_menu_boutique()
		&"entrainement":
			_menu_entrainement()
		&"choix_gone":
			_lancer_minijeu(_menu_index)
		_:
			_fermer_menu()

func _menu_pause(choix: String) -> void:
	match choix:
		"Équipe":
			_ouvrir_menu(&"equipe", _texte_equipe(), ["Fermer"])
		"Sauvegarder":
			var ok := GameState.sauvegarder()
			_fermer_menu()
			_message("Partie sauvegardée." if ok else "Échec de la sauvegarde.")
		"Retour au titre":
			GameState.sauvegarder()
			get_tree().change_scene_to_file(GameState.SCENE_MENU)

func _menu_boutique() -> void:
	var message := ""
	if _menu_index == 0:
		if GameState.consommer_ressource(&"praline", 3):
			GameState.ajouter_objet(&"filet_a_gone", 1)
			message = "Un Filet à Gone de plus."
		else:
			message = "Pas assez de pralines."
	elif _menu_index == 1:
		if GameState.consommer_ressource(&"cocon", 4):
			GameState.ajouter_objet(&"barre_de_cocon", 1)
			message = "Une Barre de cocon de plus."
		else:
			message = "Pas assez de cocons."
	_fermer_menu()
	_message(message)

func _menu_entrainement() -> void:
	_minijeu_choisi = &"rythme" if _menu_index == 0 else &"frappe"
	var noms: Array = []
	for g in GameState.equipe:
		noms.append("%s  Niv.%d" % [g.nom(), g.niveau])
	noms.append("Annuler")
	_ouvrir_menu(&"choix_gone", "Entraîner qui ?", noms)

func _lancer_minijeu(index: int) -> void:
	if index < 0 or index >= GameState.equipe.size():
		_fermer_menu()
		return
	GameState.gone_a_entrainer = index
	var scene: String = GameState.SCENE_RYTHME if _minijeu_choisi == &"rythme" else GameState.SCENE_FRAPPE
	get_tree().change_scene_to_file(scene)

func _texte_equipe() -> String:
	var lignes: Array = ["Équipe (%d/%d)" % [GameState.equipe.size(), GameState.TAILLE_EQUIPE_MAX]]
	for g in GameState.equipe:
		lignes.append("%s  Niv.%d  PV %d/%d" % [g.nom(), g.niveau, g.pv, g.pv_max()])
		lignes.append("   ATT %d  DEF %d  VIT %d" % [g.attaque(), g.defense(), g.vitesse()])
	lignes.append("")
	var sacs: Array = []
	for objet in GameState.objets_possedes():
		sacs.append("%s x%d" % [objet.display_name, GameState.quantite_objet(objet.id)])
	lignes.append("Sac : " + (", ".join(sacs) if not sacs.is_empty() else "vide"))
	return "\n".join(lignes)

func _texte_boutique() -> String:
	var lignes: Array = ["Boutique"]
	for id in GameState.RESSOURCES:
		lignes.append("%s : %d" % [GameState.RESSOURCES[id], GameState.quantite_ressource(id)])
	return "\n".join(lignes)

func _message(texte: String) -> void:
	_label_message.text = texte
