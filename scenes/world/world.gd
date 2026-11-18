extends Node2D
## La carte. Deux TileMapLayer construites depuis les plans texte de zones.gd :
## une couche de sol, et une couche de decor triee en profondeur (Y-sort), pour
## que le joueur passe derriere ce qui est devant lui.
##
## Quand l'equipe aura dessine les vraies tuiles, il suffira de remplacer le PNG
## du tileset : les plans et le code ne bougent pas.

enum Mode { LIBRE, MENU, CARTE, DIALOGUE, INVENTAIRE }

const CHANCE_RENCONTRE := 0.14
const SCENE_PNJ: PackedScene = preload("res://scenes/world/pnj.tscn")
const SCENE_TRAM: PackedScene = preload("res://scenes/world/tram.tscn")
## Une rame par tranche de cette longueur de ligne (en cases).
const CASES_PAR_TRAM := 40
## Chance qu'un PNJ se contente de tourner la tete au lieu de faire un pas.
const CHANCE_PNJ_REGARDE := 0.3
## Un PNJ place au hasard n'apparait pas a moins de cette distance du joueur.
const DISTANCE_MIN_PNJ := 5
## Niveau du boss final (Nael). Avec une equipe de 3 au niveau 13, on gagne environ
## 2 fois sur 3 (simulation, docs/regles.md « Equilibrage »).
const NIVEAU_BOSS := 12
## Le bandeau du bas reste visible ce temps-la (secondes), puis s'efface.
const DUREE_BANDEAU := 4.0
const FONDU_BANDEAU := 0.6
## L'encart du bas (nom de la zone, message) : dans le coin bas gauche, a la
## taille du texte, jamais plus large que cette part de l'ecran.
const ENCART_LARGEUR_MAX := 0.6
const ENCART_LARGEUR_MIN := 60.0
const ENCART_MARGE := 4.0
const ENCART_RETRAIT := 3.0
## Longueur d'une promenade de PNJ, en pas d'affilee.
## Ce que fait un alternant sauvage quand le joueur lui marche dessus.
## Les trois chances se completent : le reste, il hesite et ne se passe rien.
const CHANCE_ALTERNANT_SE_BAT := 0.6
const CHANCE_ALTERNANT_FUIT := 0.25
## Chance qu'un alternant passant a cote du joueur l'attaque de lui-meme.
const CHANCE_ALTERNANT_ATTAQUE := 0.12

const PAS_PROMENADE_MIN := 2
const PAS_PROMENADE_MAX := 5

## Le train de la gare de Perrache passe au loin, a intervalle irregulier,
## tant que le joueur est dans une zone qui declare une "ambiance".
const TRAIN_ATTENTE_MIN := 25.0
const TRAIN_ATTENTE_MAX := 70.0
## Les pas reviennent a chaque case : ils passent sous le reste du jeu.
const VOLUME_PAS_DB := -16.0

## action -> [deplacement, Joueur.Direction]. Les entiers suivent l'ordre de
## l'enum Direction de player.gd : BAS, HAUT, GAUCHE, DROITE.
## Direction opposee (Joueur.Direction : BAS, HAUT, GAUCHE, DROITE).
const OPPOSEE := [1, 0, 3, 2]

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
## Minuteur du train qui entre en gare. Cree au demarrage, relance a chaque
## zone qui declare une ambiance.
var _train: Timer = null
## Les identifiants des articles affiches en boutique, dans l'ordre du menu.
var _articles: Array = []
## Les temps du dialogue en cours, le premier etant celui a l'ecran.
var _dialogue: Array = []
## L'alternant a qui on parle, pour pouvoir le combattre a la fin.
var _interlocuteur: Pnj = null

@onready var _sol: TileMapLayer = %Sol
@onready var _decor: DecorCarte = %Decor
@onready var _joueur: Joueur = %Joueur
@onready var _pnjs: Node2D = %Pnjs
@onready var _trams: Node2D = %Trams
@onready var _carte: CarteMonde = %CarteMonde
@onready var _inventaire: Inventaire = %Inventaire
@onready var _label_zone: Label = %Zone
@onready var _label_message: Label = %Message
var _fondu_bandeau: Tween
var _mini_carte: MiniCarte
## Le personnage a cote du joueur a qui on propose de parler (null : personne).
var _invite: Pnj = null
@onready var _bandeau: ColorRect = %Bandeau
@onready var _volet: ColorRect = %Volet
@onready var _overlay: Label = %Overlay

func _ready() -> void:
	GameState.assurer_partie()
	# Une replique de dialogue est plus longue qu'une ligne de menu : sans ca,
	# elle sortirait du volet par la droite.
	_overlay.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameState.jouer_musique(&"exploration")
	_train = Timer.new()
	_train.one_shot = true
	_train.timeout.connect(_sur_train)
	add_child(_train)
	_joueur.deplacement_fini.connect(_sur_case_atteinte)
	_carte.fermee.connect(_sur_carte_fermee)
	_inventaire.fermee.connect(_sur_carte_fermee)
	# la mini-carte, sous les autres ecrans du Hud (carte du monde, inventaire)
	_mini_carte = MiniCarte.new()
	_bandeau.get_parent().add_child(_mini_carte)
	_bandeau.get_parent().move_child(_mini_carte, 0)
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
	_joueur.placer(depart)
	_placer_pnj()
	_placer_trams()
	_joueur.borner_camera(Zones.taille_pixels(id))
	_label_zone.text = str(zone["titre"])
	_montrer_bandeau()
	_poser_ambiance()

## Le fond sonore de la zone : la gare a le sien, les autres sont muettes.
## C'est une donnee de zone (cle "ambiance" dans zones.gd), pas une liste ici.
func _poser_ambiance() -> void:
	# La carte peut etre en train de quitter l'arbre (retour au titre pendant
	# un changement de zone) : un minuteur hors de l'arbre refuse de partir.
	if _train == null or not _train.is_inside_tree():
		return
	var ambiance := StringName(zone.get("ambiance", &""))
	if ambiance == &"":
		GameState.arreter_ambiance()
		_train.stop()
		return
	GameState.jouer_ambiance(ambiance)
	_train.start(randf_range(TRAIN_ATTENTE_MIN, TRAIN_ATTENTE_MAX))

## Un train entre en gare, puis on en attend un autre.
func _sur_train() -> void:
	if not _train.is_inside_tree():
		return
	GameState.jouer_son(&"train_en_gare", GameState.VOLUME_TRAIN_DB)
	_train.start(randf_range(TRAIN_ATTENTE_MIN, TRAIN_ATTENTE_MAX))

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
				_poser(_sol, cellule, Zones.sol_de_zone(zone_id, c, cellule))
			if c == "R":
				var tuile: Vector2i = Zones.TUILES_RESSOURCES.get(zone["ressource"], zone["tuile_ressource"])
				_decor.set_cell(cellule, Zones.TUILES, tuile)
			elif c == "#":
				_poser(_decor, cellule, Zones.decor_batiment(zone_id, cellule))
			elif Zones.DECORS.has(c):
				_poser(_decor, cellule, Zones.DECORS[c])
	# Deuxieme passe : la partie haute des volumes deborde sur la case du dessus.
	for y in plan.size():
		var ligne2: String = plan[y]
		for x in ligne2.length():
			var c2: String = ligne2[x]
			if (not Zones.DECORS_HAUT.has(c2) and c2 != "#") or y == 0:
				continue
			var dessus := Vector2i(x, y - 1)
			if Zones.case_a(zone_id, dessus) == c2:
				continue          # un autre bloc du meme volume : rien a coiffer
			if c2 == "#":
				_poser(_decor, dessus, Zones.haut_batiment(zone_id, Vector2i(x, y)))
			else:
				_poser(_decor, dessus, Zones.DECORS_HAUT[c2])

# =============================================================================
# Deplacement
# =============================================================================
func _process(_delta: float) -> void:
	_voir_le_joueur()
	_suivre_mini_carte()
	_proposer_de_parler()
	# Touche maintenue : on enchaine les pas tant qu'elle est enfoncee.
	if _mode != Mode.LIBRE or _joueur.en_mouvement:
		return
	for action in DIRECTIONS:
		if Input.is_action_pressed(action):
			_tenter_pas(action)
			return

## Le decor qui cache le joueur devient transparent : on regarde les cases que
## couvre son image, a sa position du moment (il peut etre entre deux cases).
func _voir_le_joueur() -> void:
	var p := _joueur.position
	var demi := Vector2(Zones.TAILLE_CASE * 0.3, Zones.TAILLE_CASE * 0.45)
	var haut_gauche := Vector2i(((p - demi) / Zones.TAILLE_CASE).floor())
	var bas_droite := Vector2i(((p + demi) / Zones.TAILLE_CASE).floor())
	var cases: Array[Vector2i] = []
	for y in range(haut_gauche.y, bas_droite.y + 1):
		for x in range(haut_gauche.x, bas_droite.x + 1):
			cases.append(Vector2i(x, y))
	_decor.voir_a_travers(cases)

## Un pas, ou un simple demi-tour si la case est bloquee.
func _tenter_pas(action: String) -> void:
	if _joueur.en_mouvement:
		return
	var consigne: Array = DIRECTIONS[action]
	var cible: Vector2i = _joueur.cellule + consigne[0]
	if _tram_sur(cible) != null:
		_joueur.regarder(consigne[1])
		_message("Ding ding ! Attention au tram.")
		return
	var hauteur: int = zone["plan"].size()
	if cible.y < 0 or cible.y >= hauteur:
		_passer_dans_la_bande_voisine(cible, consigne[1])
		return
	if not Zones.est_traversable(zone_id, cible):
		_joueur.regarder(consigne[1])
		return
	var croise := _pnj_sur(cible)
	if croise != null:
		# On ne se bloque pas entre personnages : on se croise, chacun prend la case
		# de l'autre (seuls les pieds comptent, et ils restent au centre de leur case).
		if croise.en_mouvement:
			_joueur.regarder(consigne[1])
			return
		croise.pas_restants = 0
		croise.avancer_vers(_joueur.cellule, OPPOSEE[consigne[1]] as Joueur.Direction)
	GameState.jouer_son(&"marche", VOLUME_PAS_DB)
	_joueur.avancer_vers(cible, consigne[1])

## Les zones sont des bandes collees : sortir par le haut ou le bas mene a la bande
## voisine, sur la meme colonne. Bloque si la case d'en face est un mur ou de l'eau.
func _passer_dans_la_bande_voisine(cible: Vector2i, direction: Joueur.Direction) -> void:
	var sens := -1 if cible.y < 0 else 1
	var voisine := Zones.zone_voisine(zone_id, sens)
	if voisine == &"":
		_joueur.regarder(direction)
		return
	var arrivee := Vector2i(cible.x, Zones.zone(voisine)["plan"].size() - 1 if sens < 0 else 0)
	if not Zones.est_traversable(voisine, arrivee):
		_joueur.regarder(direction)
		return
	_charger_zone(voisine, arrivee)
	_joueur.regarder(direction)
	_message("Vous arrivez : %s" % zone["titre"])
	GameState.sauvegarde_auto()

func _sur_case_atteinte(cellule: Vector2i) -> void:
	GameState.case_joueur = cellule
	var c := _case_courante()
	var sorties: Dictionary = zone["sorties"]
	if sorties.has(c):
		var sortie: Array = sorties[c]
		GameState.jouer_son(&"entree_lieu")
		_charger_zone(StringName(sortie[0]), Vector2i(int(sortie[1]), int(sortie[2])))
		_message("Vous arrivez : %s" % zone["titre"])
		GameState.sauvegarde_auto()
		return
	match c:
		"T":
			var sortie_traboule := Zones.autre_traboule(zone_id, cellule)
			GameState.jouer_son(&"entree_lieu")
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
			return "Machine à café. Entrée pour remotiver l'équipe."
		"B":
			return "Boutique. Entrée pour dépenser la note de frais."
		"M":
			return "Entraînement. Entrée pour lancer un mini-jeu."
		"X":
			return "Nael (Niv.%d) garde l'EEMI. Mieux vaut une équipe vers le Niv.%d. Entrée pour l'affronter." \
				% [NIVEAU_BOSS, NIVEAU_BOSS + 1]
		_:
			return ""

# =============================================================================
# PNJ qui se baladent
# =============================================================================
func _placer_pnj() -> void:
	for ancien in _pnjs.get_children():
		_pnjs.remove_child(ancien)
		ancien.queue_free()
	# Tires au hasard parmi tous les personnages du jeu, doublons permis ; un
	# alternant deja recrute est dans l'equipe, il ne se balade plus.
	var possibles: Array = Zones.tous_les_pnj().filter(
		func(f: Dictionary) -> bool: return not GameState.drapeau(StringName(f["cle"])))
	for i in Zones.NOMBRE_PNJ:
		if possibles.is_empty():
			return
		var depart := _case_au_hasard_pour_pnj()
		if depart == Vector2i(-1, -1):
			return                # zone pleine : on n'insiste pas
		var fiche: Dictionary = possibles.pick_random()
		var pnj: Pnj = SCENE_PNJ.instantiate()
		pnj.name = "Pnj%d" % i
		pnj.set_meta(&"fiche", fiche)
		pnj.frames = load(str(fiche["frames"]))
		_pnjs.add_child(pnj)
		pnj.placer(depart)
		pnj.envie_de_bouger.connect(_sur_envie_pnj)

## Le nom affiche d'un personnage (plusieurs peuvent porter le meme).
func _nom_de(alternant: Pnj) -> String:
	return str(alternant.get_meta(&"fiche", {}).get("nom", alternant.name))

## Une case de sol autorise, libre et pas trop pres du joueur ; (-1, -1) si aucune.
func _case_au_hasard_pour_pnj() -> Vector2i:
	var candidates: Array[Vector2i] = []
	var plan: Array = zone["plan"]
	for y in plan.size():
		for x in str(plan[y]).length():
			var c := Vector2i(x, y)
			var ecart: Vector2i = (c - _joueur.cellule).abs()
			if Zones.accepte_pnj(zone_id, c) and _case_libre(c) and ecart.x + ecart.y >= DISTANCE_MIN_PNJ:
				candidates.append(c)
	if candidates.is_empty():
		return Vector2i(-1, -1)
	return candidates.pick_random()

## Le PNJ demande a bouger : la carte choisit une case libre autour de lui.
## En pleine promenade, il continue tout droit ; sinon il en commence une
## nouvelle (2 a 5 pas) dans une direction au hasard, ou regarde juste autour.
func _sur_envie_pnj(pnj: Pnj) -> void:
	if _mode != Mode.LIBRE:
		pnj.regarder(pnj.direction)
		return
	# A cote du joueur, il s'arrete et le regarde : on peut lui parler.
	if _a_cote_du_joueur(pnj):
		pnj.pas_restants = 0
		pnj.regarder(_direction_de(_joueur.cellule - pnj.cellule))
		return
	var deplacement: Vector2i
	var vers: Joueur.Direction
	if pnj.pas_restants > 0:
		vers = pnj.direction
		deplacement = DIRECTIONS.values()[int(vers)][0]
	else:
		var consigne: Array = DIRECTIONS.values().pick_random()
		deplacement = consigne[0]
		vers = consigne[1]
		if randf() < CHANCE_PNJ_REGARDE:
			pnj.regarder(vers)
			return
		pnj.pas_restants = randi_range(PAS_PROMENADE_MIN, PAS_PROMENADE_MAX)
	var cible: Vector2i = pnj.cellule + deplacement
	var ecart: Vector2i = (cible - pnj.case_depart).abs()
	var dans_le_rayon: bool = pnj.rayon < 0 or maxi(ecart.x, ecart.y) <= pnj.rayon
	if Zones.accepte_pnj(zone_id, cible) and _case_libre(cible) and dans_le_rayon:
		pnj.avancer_vers(cible, vers)
		_tenter_agression(pnj)
		return
	# Deux PNJ face a face se croisent au lieu de se bloquer.
	var croise := _pnj_sur(cible)
	if croise != null and croise != pnj and not croise.en_mouvement and dans_le_rayon \
			and Zones.accepte_pnj(zone_id, cible) and _tram_sur(cible) == null:
		croise.pas_restants = 0
		croise.avancer_vers(pnj.cellule, OPPOSEE[vers] as Joueur.Direction)
		pnj.avancer_vers(cible, vers)
	else:
		pnj.regarder(vers)
		_tenter_agression(pnj)

# =============================================================================
# Rencontrer un alternant sauvage
# =============================================================================
## Le joueur marche sur un alternant. Il ne decide pas de ce qui suit : l'autre
## se bat, s'enfuit, ou ne fait rien. C'est son humeur, pas un menu.
func _aborder(alternant: Pnj) -> void:
	match reaction(randf()):
		&"combat":
			_message("%s ne compte pas se laisser recruter !" % _nom_de(alternant))
			_combattre(alternant)
		&"fuite":
			_message("%s file sans demander son reste." % _nom_de(alternant))
			_faire_fuir(alternant)
		_:
			_message("%s vous ignore poliment." % _nom_de(alternant))

## Ce que decide un alternant aborde, pour un tirage entre 0 et 1. Sortie a part
## du reste pour pouvoir la verifier sans lancer le jeu.
static func reaction(hasard: float) -> StringName:
	if hasard < CHANCE_ALTERNANT_SE_BAT:
		return &"combat"
	if hasard < CHANCE_ALTERNANT_SE_BAT + CHANCE_ALTERNANT_FUIT:
		return &"fuite"
	return &"ignore"

## Il s'ecarte du joueur et continue sur sa lancee.
func _faire_fuir(alternant: Pnj) -> void:
	var ecart: Vector2i = alternant.cellule - _joueur.cellule
	var deplacement := Vector2i(signi(ecart.x), 0) if absi(ecart.x) >= absi(ecart.y) \
		else Vector2i(0, signi(ecart.y))
	if deplacement == Vector2i.ZERO:
		return
	var vers: Joueur.Direction = _direction_de(deplacement)
	var cible: Vector2i = alternant.cellule + deplacement
	if Zones.accepte_pnj(zone_id, cible) and _case_libre(cible):
		alternant.pas_restants = PAS_PROMENADE_MAX
		alternant.avancer_vers(cible, vers)
	else:
		alternant.regarder(vers)

## Il attaque de lui-meme en passant a cote du joueur.
func _tenter_agression(alternant: Pnj) -> bool:
	if _mode != Mode.LIBRE or _joueur.en_mouvement:
		return false
	var ecart: Vector2i = (alternant.cellule - _joueur.cellule).abs()
	if ecart.x + ecart.y != 1:
		return false
	if randf() >= CHANCE_ALTERNANT_ATTAQUE:
		return false
	_message("%s vous barre la route !" % _nom_de(alternant))
	_combattre(alternant)
	return true

func _combattre(alternant: Pnj) -> void:
	var fiche: GoneData = _fiche_de(alternant)
	if fiche == null:
		return
	GameState.rencontre_en_attente = fiche
	GameState.niveau_rencontre = randi_range(int(zone["niveau_min"]), int(zone["niveau_max"]))
	GameState.combat_est_boss = false
	GameState.pnj_en_combat = StringName(alternant.get_meta(&"fiche", {}).get("cle", ""))
	get_tree().change_scene_to_file(GameState.SCENE_COMBAT)

## La fiche de l'alternant : celle que la zone lui attribue, sinon une au hasard.
func _fiche_de(alternant: Pnj) -> GoneData:
	var entree: Dictionary = alternant.get_meta(&"fiche", {})
	if entree.has("gone"):
		var fiche: GoneData = GameState.catalogue_gones.get(entree["gone"])
		if fiche != null:
			return fiche
	var sauvages := GameState.gones_sauvages()
	return sauvages.pick_random() if not sauvages.is_empty() else null

## La case que le joueur a devant lui.
func _case_devant() -> Vector2i:
	for consigne: Array in DIRECTIONS.values():
		if consigne[1] == _joueur.direction:
			return _joueur.cellule + consigne[0]
	return _joueur.cellule

## Un personnage arrete sur une case voisine du joueur, celui d'en face d'abord.
func _pnj_voisin() -> Pnj:
	var devant := _pnj_sur(_case_devant())
	if devant != null and not devant.en_mouvement:
		return devant
	for pnj: Pnj in _pnjs.get_children():
		if not pnj.en_mouvement and _a_cote_du_joueur(pnj):
			return pnj
	return null

func _a_cote_du_joueur(pnj: Pnj) -> bool:
	var ecart: Vector2i = (pnj.cellule - _joueur.cellule).abs()
	return ecart.x + ecart.y == 1

## Quand un personnage est a cote, le bandeau propose de lui parler, et le reste
## tant qu'il est la.
func _proposer_de_parler() -> void:
	var voisin: Pnj = null
	if _mode == Mode.LIBRE and not _joueur.en_mouvement:
		voisin = _pnj_voisin()
	if voisin == _invite:
		return
	_invite = voisin
	if voisin != null:
		_label_message.text = "Entrée : parler à %s" % _nom_de(voisin)
		_montrer_bandeau(true)
	else:
		_label_message.text = ""
		_montrer_bandeau()

func _suivre_mini_carte() -> void:
	_mini_carte.visible = _mode != Mode.CARTE and _mode != Mode.INVENTAIRE
	if not _mini_carte.visible:
		return
	var positions: Array[Vector2i] = []
	for pnj: Pnj in _pnjs.get_children():
		positions.append(pnj.cellule)
	_mini_carte.suivre(zone_id, _joueur.cellule, positions)

func _direction_de(deplacement: Vector2i) -> Joueur.Direction:
	for consigne: Array in DIRECTIONS.values():
		if consigne[0] == deplacement:
			return consigne[1]
	return Joueur.Direction.BAS

## Libre = ni le joueur (ou la case ou il va), ni un PNJ.
func _case_libre(c: Vector2i) -> bool:
	return c != _joueur.cellule and _pnj_sur(c) == null and _tram_sur(c) == null

# =============================================================================
# Tramways
# =============================================================================
## Une rame par ligne de tram de la zone (plus pour les longues lignes).
func _placer_trams() -> void:
	for ancien in _trams.get_children():
		_trams.remove_child(ancien)
		ancien.queue_free()
	for ligne: Array[Vector2i] in _lignes_de_tram():
		if ligne.size() < Tram.LONGUEUR * 3:
			continue
		var nombre: int = 1 + ligne.size() / CASES_PAR_TRAM
		for k in nombre:
			var tram: Tram = SCENE_TRAM.instantiate()
			_trams.add_child(tram)
			tram.demarrer(ligne, Tram.LONGUEUR - 1 + k * ligne.size() / nombre)
			tram.envie_d_avancer.connect(_sur_envie_tram)

## Les lignes de tram de la zone : chaque groupe de rails relies, parcouru d'un bout
## a l'autre (en allant tout droit tant que possible aux embranchements).
func _lignes_de_tram() -> Array:
	var rails := {}
	var plan: Array = zone["plan"]
	for y in plan.size():
		for x in str(plan[y]).length():
			if str(plan[y])[x] == "r":
				rails[Vector2i(x, y)] = true
	var lignes: Array = []
	var vus := {}
	var directions := [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]
	for depart in rails:
		if vus.has(depart):
			continue
		# un bout de la ligne : la case la plus loin du depart, dans son groupe
		var groupe := [depart]
		vus[depart] = true
		var i := 0
		while i < groupe.size():
			for d in directions:
				var v: Vector2i = groupe[i] + d
				if rails.has(v) and not vus.has(v):
					vus[v] = true
					groupe.append(v)
			i += 1
		var bout: Vector2i = groupe[-1]
		# parcours depuis ce bout
		var ligne: Array[Vector2i] = [bout]
		var deja := {bout: true}
		var cap := Vector2i.ZERO
		while true:
			var suivant := Vector2i(-1, -1)
			var choix: Array = [cap] + directions
			for d in choix:
				var v: Vector2i = ligne[-1] + d
				if d != Vector2i.ZERO and rails.has(v) and not deja.has(v):
					suivant = v
					cap = d
					break
			if suivant == Vector2i(-1, -1):
				break
			deja[suivant] = true
			ligne.append(suivant)
		lignes.append(ligne)
	return lignes

func _sur_envie_tram(tram: Tram) -> void:
	var c := tram.prochaine_case()
	var autre := _tram_sur(c)
	if _mode == Mode.LIBRE and c != _joueur.cellule and _pnj_sur(c) == null \
			and (autre == null or autre == tram):
		tram.avancer()
	else:
		tram.attendre()

func _tram_sur(c: Vector2i) -> Tram:
	for tram: Tram in _trams.get_children():
		if c in tram.cases:
			return tram
	return null

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
	GameState.lever_drapeau(cle)
	GameState.jouer_son(&"achat")
	GameState.ajouter_note_de_frais(GameState.GAIN_RAMASSAGE)
	_decor.set_cell(cellule, -1)          # l'objet ramasse disparait
	_poser(_sol, cellule, Zones.SOLS["h"])
	_message("Note de frais : +%d (total %d)"
		% [GameState.GAIN_RAMASSAGE, GameState.note_de_frais])

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
		_message("L'EEMI est calme. Fin du MVP : merci d'avoir joué.")
		return
	var gardien: GoneData = GameState.catalogue_gones.get(&"nael")
	if gardien == null:
		_message("Nael est introuvable (data/gones manquant).")
		return
	GameState.rencontre_en_attente = gardien
	GameState.niveau_rencontre = NIVEAU_BOSS
	GameState.combat_est_boss = true
	get_tree().change_scene_to_file(GameState.SCENE_COMBAT)

# =============================================================================
# Interaction et menus
# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if _mode == Mode.CARTE or _mode == Mode.INVENTAIRE:
		return               # la carte du monde et l'inventaire gerent leurs touches
	if _mode == Mode.MENU:
		_input_menu(event)
		return
	if _mode == Mode.DIALOGUE:
		_input_dialogue(event)
		return
	if event.is_action_pressed("ui_cancel"):
		_ouvrir_menu(&"pause", "Menu", ["Équipe", "Carte", "Sauvegarder", "Retour au titre", "Reprendre"])
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
	# Un alternant juste devant : le joueur choisit de l'aborder, et celui-ci
	# n'a pas son mot a dire. C'est la difference avec la rencontre subie, ou
	# l'autre decide de se battre, de fuir ou d'ignorer.
	var alternant := _pnj_sur(_case_devant())
	if alternant == null:
		alternant = _pnj_voisin()
	if alternant != null:
		# chacun se tourne vers l'autre, puis on parle
		_joueur.regarder(_direction_de(alternant.cellule - _joueur.cellule))
		alternant.regarder(_direction_de(_joueur.cellule - alternant.cellule))
		_parler_a(alternant)
		return
	match _case_courante():
		"S":
			GameState.soigner_equipe()
			GameState.jouer_son(&"niveau_gagne")
			GameState.ajuster_bienveillance(1, "machine à café")
			GameState.sauvegarde_auto()
			_message("La machine à café a fait son office. Équipe au complet.")
		"B":
			_ouvrir_boutique()
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


# =============================================================================
# Dialogues de la carte
# =============================================================================
## Aborder un alternant : il parle, le joueur repond, et c'est seulement
## ensuite qu'il est question de lui tendre un contrat.
func _parler_a(alternant: Pnj) -> void:
	var fiche := _fiche_de(alternant)
	var id: StringName = fiche.id if fiche != null else &""
	var cle := StringName("parle_%s" % id)
	_interlocuteur = alternant
	_dialogue = Dialogues.pour(id, _nom_de(alternant), GameState.drapeau(cle))
	GameState.lever_drapeau(cle)
	_mode = Mode.DIALOGUE
	_menu_index = 0
	_afficher_temps()

## Met a l'ecran le temps courant : une replique, ou une question a choix.
func _afficher_temps() -> void:
	if _dialogue.is_empty():
		_fermer_dialogue()
		return
	var temps: Dictionary = _dialogue[0]
	var lignes: Array = []
	if temps.has("question"):
		lignes.append(str(temps["question"]))
		lignes.append("")
		var choix: Array = temps["choix"]
		for i in choix.size():
			var texte: String = str(choix[i]["texte"])
			lignes.append(("> %s" % texte) if i == _menu_index else ("  %s" % texte))
	else:
		var locuteur := str(temps.get("locuteur", ""))
		if not locuteur.is_empty():
			lignes.append(locuteur.to_upper())
		lignes.append(str(temps["texte"]))
		lignes.append("")
		lignes.append("  [Entrée]")
	_overlay.text = "\n".join(lignes)
	_volet.visible = true
	_overlay.visible = true

func _input_dialogue(event: InputEvent) -> void:
	var temps: Dictionary = _dialogue[0] if not _dialogue.is_empty() else {}
	var choix: Array = temps.get("choix", [])
	if not choix.is_empty():
		if event.is_action_pressed("ui_down"):
			_menu_index = (_menu_index + 1) % choix.size()
			GameState.jouer_son(&"clic")
			_afficher_temps()
			return
		if event.is_action_pressed("ui_up"):
			_menu_index = (_menu_index - 1 + choix.size()) % choix.size()
			GameState.jouer_son(&"clic")
			_afficher_temps()
			return
	if not event.is_action_pressed("ui_accept"):
		return
	GameState.jouer_son(&"dialogue_suivant")
	_dialogue.pop_front()
	if choix.is_empty():
		_menu_index = 0
		_afficher_temps()
		return
	_repondre(choix[_menu_index])

## Applique la reponse choisie : la Bienveillance, puis la replique du patron,
## puis l'action eventuelle (aujourd'hui, le combat).
func _repondre(reponse: Dictionary) -> void:
	var variation := int(reponse.get("bienveillance", 0))
	if variation != 0:
		GameState.ajuster_bienveillance(variation, "réponse à un alternant")
	var action: StringName = reponse.get("action", &"rien")
	if action == &"combat":
		var alternant := _interlocuteur
		_fermer_dialogue()
		if alternant != null:
			_combattre(alternant)
		return
	var replique := str(reponse.get("reponse", ""))
	if not replique.is_empty():
		_dialogue.push_front({"texte": replique})
	_menu_index = 0
	_afficher_temps()

func _fermer_dialogue() -> void:
	_dialogue.clear()
	_interlocuteur = null
	_mode = Mode.LIBRE
	_menu_index = 0
	_volet.visible = false
	_overlay.visible = false

func _ouvrir_menu(contexte: StringName, titre: String, options: Array) -> void:
	if contexte == &"boutique":
		GameState.jouer_son(&"entree_boutique")
		GameState.jouer_musique(&"boutique")
	_menu_contexte = contexte
	_menu_titre = titre
	_menu_options = options
	_menu_index = 0
	_mode = Mode.MENU
	_rafraichir_overlay()

func _fermer_menu() -> void:
	if _menu_contexte == &"boutique":
		GameState.jouer_musique(&"exploration")
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
		GameState.jouer_son(&"clic")
		_rafraichir_overlay()
	elif event.is_action_pressed("ui_up"):
		_menu_index = (_menu_index - 1 + _menu_options.size()) % _menu_options.size()
		GameState.jouer_son(&"clic")
		_rafraichir_overlay()
	elif event.is_action_pressed("ui_cancel"):
		GameState.jouer_son(&"dialogue_suivant")
		_fermer_menu()
	elif event.is_action_pressed("ui_accept"):
		GameState.jouer_son(&"dialogue_suivant")
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

func _sur_carte_fermee() -> void:
	_mode = Mode.LIBRE

func _menu_pause(choix: String) -> void:
	match choix:
		"Équipe":
			_fermer_menu()
			_mode = Mode.INVENTAIRE
			_inventaire.ouvrir()
		"Carte":
			_fermer_menu()
			_mode = Mode.CARTE
			_carte.ouvrir(zone_id, _joueur.cellule)
		"Sauvegarder":
			var ok := GameState.sauvegarder()
			_fermer_menu()
			_message("Partie sauvegardée." if ok else "Échec de la sauvegarde.")
		"Retour au titre":
			GameState.sauvegarder()
			get_tree().change_scene_to_file(GameState.SCENE_MENU)

## La boutique liste le catalogue de GameState, avec son prix.
func _ouvrir_boutique() -> void:
	_articles.clear()
	var lignes: Array = []
	for id: StringName in GameState.BOUTIQUE:
		var objet: ItemData = GameState.catalogue_objets.get(id)
		if objet == null:
			continue                      # un objet retire de data/ ne s'affiche pas
		_articles.append(id)
		lignes.append("%s — %d" % [objet.display_name, GameState.prix(id)])
	lignes.append("Annuler")
	_ouvrir_menu(&"boutique", "Note de frais : %d" % GameState.note_de_frais, lignes)

func _menu_boutique() -> void:
	if _menu_index < 0 or _menu_index >= _articles.size():
		_fermer_menu()
		return
	var id: StringName = _articles[_menu_index]
	var objet: ItemData = GameState.catalogue_objets.get(id)
	var message := ""
	if objet == null:
		message = "Cet article n'existe plus."
	elif GameState.depenser_note_de_frais(GameState.prix(id)):
		GameState.ajouter_objet(id, 1)
		GameState.jouer_son(&"achat")
		message = "%s acheté. Il reste %d de note de frais." % [
			objet.display_name, GameState.note_de_frais]
	else:
		message = "Pas assez de note de frais."
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

func _message(texte: String) -> void:
	_label_message.text = texte
	_montrer_bandeau()

## Le bandeau du bas (nom de la zone, message) ne cache pas la carte : il apparait
## avec un message ou a l'entree d'une zone, puis s'efface au bout de
## DUREE_BANDEAU secondes.
## Place l'encart dans le coin bas gauche, a la taille de son texte : il ne barre
## plus tout l'ecran et cache le moins possible la carte et le joueur.
func _disposer_encart() -> void:
	var ecran := get_viewport_rect().size
	var police := _label_message.get_theme_font(&"font")
	var taille_zone := _label_zone.get_theme_font_size(&"font_size")
	var taille_message := _label_message.get_theme_font_size(&"font_size")
	var large_zone := police.get_string_size(_label_zone.text, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_zone).x
	var large_message := police.get_string_size(_label_message.text, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_message).x
	var largeur := clampf(maxf(large_zone, large_message) + ENCART_RETRAIT * 2.0 + 4.0, ENCART_LARGEUR_MIN,
		ecran.x * ENCART_LARGEUR_MAX)
	var interieur := largeur - ENCART_RETRAIT * 2.0
	# hauteur d'apres la police : une ligne de titre, et le message sur autant de
	# lignes qu'il lui en faut a cette largeur
	var haut_zone := police.get_height(taille_zone)
	var lignes := ceili(large_message / maxf(interieur - 4.0, 1.0)) if _label_message.text != "" else 0
	var haut_message := police.get_height(taille_message) * lignes
	for label: Label in [_label_zone, _label_message]:
		label.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		label.custom_minimum_size = Vector2.ZERO
	_label_zone.size = Vector2(interieur, haut_zone)
	_label_message.size = Vector2(interieur, haut_message)
	_label_message.visible = lignes > 0
	var hauteur := haut_zone + haut_message + ENCART_RETRAIT * 2.0
	_bandeau.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_bandeau.position = Vector2(ENCART_MARGE, ecran.y - ENCART_MARGE - hauteur)
	_bandeau.size = Vector2(largeur, hauteur)
	_label_zone.position = _bandeau.position + Vector2(ENCART_RETRAIT, ENCART_RETRAIT)
	_label_message.position = _label_zone.position + Vector2(0, haut_zone)

func _montrer_bandeau(persistant: bool = false) -> void:
	_disposer_encart()
	if _fondu_bandeau != null and _fondu_bandeau.is_valid():
		_fondu_bandeau.kill()
	for noeud: CanvasItem in [_bandeau, _label_zone, _label_message]:
		noeud.modulate.a = 1.0
	if persistant:
		return                # reste affiche jusqu'au prochain appel
	_fondu_bandeau = create_tween()
	_fondu_bandeau.tween_interval(DUREE_BANDEAU)
	_fondu_bandeau.tween_property(_bandeau, "modulate:a", 0.0, FONDU_BANDEAU)
	_fondu_bandeau.parallel().tween_property(_label_zone, "modulate:a", 0.0, FONDU_BANDEAU)
	_fondu_bandeau.parallel().tween_property(_label_message, "modulate:a", 0.0, FONDU_BANDEAU)
