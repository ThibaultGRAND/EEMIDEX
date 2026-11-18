extends Node
## Autoload unique du projet : équipe, inventaire, note de frais, progression
## et sauvegarde. Tout le reste communique par signaux ou passe par ici.

signal equipe_modifiee
signal inventaire_modifie
signal note_de_frais_modifiee

const CHEMIN_SAUVEGARDE := "user://sauvegarde_gones.json"
const TAILLE_EQUIPE_MAX := 3

const SCENE_MENU := "res://scenes/ui/main_menu.tscn"
const SCENE_MONDE := "res://scenes/world/world.tscn"
const SCENE_COMBAT := "res://scenes/battle/battle.tscn"
const SCENE_RYTHME := "res://scenes/minigames/rythme/rythme.tscn"
const SCENE_FRAPPE := "res://scenes/minigames/frappe/frappe.tscn"
const SCENE_FIN := "res://scenes/ui/fin.tscn"

## Les musiques de fond. Une seule joue a la fois, en boucle, et les scenes
## demandent celle qu'elles veulent : la carte ne connait pas le combat.
const MUSIQUES := {
	&"exploration": "res://assets/audio/exploration.ogg",
	&"combat": "res://assets/audio/combat.ogg",
	&"boutique": "res://assets/audio/boutique.ogg",
}
## Volume de la musique, en decibels. La musique reste derriere le jeu.
const VOLUME_MUSIQUE_DB := -12.0
## Temps du fondu entre deux pistes, en secondes.
const DUREE_FONDU := 0.5
## Volume d'une piste qui s'efface. -80 dB, c'est le silence pour Godot.
const VOLUME_SILENCE_DB := -80.0

## Les bruitages : courts, joues par-dessus la musique, plusieurs a la fois.
const SONS := {
	&"clic": "res://assets/audio/clic.ogg",
	&"dialogue_suivant": "res://assets/audio/dialogue_suivant.ogg",
	&"attaque": "res://assets/audio/attaque.ogg",
	&"victoire": "res://assets/audio/victoire.ogg",
	&"defaite": "res://assets/audio/defaite.ogg",
	&"niveau_gagne": "res://assets/audio/niveau_gagne.ogg",
	&"achat": "res://assets/audio/achat.ogg",
	&"entree_boutique": "res://assets/audio/entree_boutique.ogg",
	&"entree_lieu": "res://assets/audio/entree_lieu.ogg",
	&"marche": "res://assets/audio/marche.ogg",
	&"train_en_gare": "res://assets/audio/train_en_gare.ogg",
}
## Les sons en boucle, sous la musique : l'ambiance d'une zone, et la machine
## a ecrire de la boite de dialogue.
const BOUCLES := {
	&"ambiance_gare": "res://assets/audio/ambiance_gare.ogg",
	&"texte": "res://assets/audio/texte.ogg",
}
## Volume des bruitages, de l'ambiance de zone et de la machine a ecrire.
## L'ambiance et le texte passent sous la musique : on doit les deviner, pas
## les entendre.
const VOLUME_SONS_DB := -8.0
const VOLUME_AMBIANCE_DB := -20.0
const VOLUME_TEXTE_DB := -18.0
## Le train de Perrache passe au loin : encore plus bas que l'ambiance.
const VOLUME_TRAIN_DB := -22.0
## Nombre de bruitages qui peuvent se chevaucher sans se couper.
const LECTEURS_SONS := 6

## Les deux patrons jouables. Celui qu'on ne choisit pas devient le rival.
## Voir docs/histoire.md section 2.
const HEROS := {
	&"moustache": {
		"nom": "Moustache",
		"societe": "Moustache Corp",
		"titre": "Monsieur le Président",
		"bonus": "+10 % de recrutement",
		"replique": "Un alternant, c'est un CDI sans les inconvénients.",
		"frames": "res://assets/characters/joueur_moustache/joueur_moustache_frames.tres",
		"teinte": Color(1, 1, 1),
	},
	&"moustachette": {
		"nom": "Moustachette",
		"societe": "Moustachette & Associés",
		"titre": "Madame la Présidente",
		"bonus": "+1 niveau de progression",
		"replique": "Je ne les exploite pas. Je les fais monter en compétences.",
		# Placeholder : elle n'a pas encore de planche, elle emprunte celle de
		# Moustache avec une teinte, en attendant que l'equipe la dessine.
		"frames": "res://assets/characters/joueur_moustache/joueur_moustache_frames.tres",
		"teinte": Color(1.0, 0.72, 0.86),
	},
}

## Ce que rapporte un objet ramasse sur la carte.
const GAIN_RAMASSAGE := 25

## Le catalogue de la boutique : objet -> prix en Note de Frais.
const BOUTIQUE := {
	&"filet_a_gone": 30,
	&"contrat_tickets_resto": 70,
	&"contrat_teletravail": 140,
	&"mache_praline": 25,
	&"barre_de_cocon": 55,
}

# --- Catalogues chargés depuis data/ au démarrage -----------------------------
var catalogue_gones: Dictionary = {}
var catalogue_attaques: Dictionary = {}
var catalogue_objets: Dictionary = {}

# --- État de la partie --------------------------------------------------------
var equipe: Array = []           # Array[GoneInstance], 3 max
var inventaire: Dictionary = {}  # item_id (StringName) -> quantité (int)
## La monnaie du jeu. En tant que patron, on en a beaucoup.
var note_de_frais: int = 0
var drapeaux: Dictionary = {}    # progression : objets ramassés, boss battu...
var partie_commencee: bool = false
## La Bienveillance RH : le compteur cache qui decide de la fin.
## Il part de zero et il faut le faire monter pour obtenir la bonne fin :
## ne rien faire de particulier mene a la fin exploiteuse. Voir docs/regles.md.
var bienveillance: int = 0

## Le patron choisi au prologue.
var heros: StringName = &"moustache"

# --- Position du joueur -------------------------------------------------------
var zone_courante: StringName = &"perrache"
var case_joueur := Vector2i(12, 10)

# --- Contexte passé d'une scène à l'autre ------------------------------------
var rencontre_en_attente: GoneData = null
var niveau_rencontre: int = 4
var combat_est_boss: bool = false
## L'alternant de la carte avec qui on se bat, sous la forme "zone_Nom".
## Recrute, il disparait de la carte : le drapeau du meme nom est leve.
var pnj_en_combat: StringName = &""
var gone_a_entrainer: int = 0      # index dans l'équipe
var dernier_resultat_combat: String = ""

# --- Musique ------------------------------------------------------------------
var musique_courante: StringName = &""
var _lecteur_musique: AudioStreamPlayer = null
var _fondu: Tween = null

# --- Sons ---------------------------------------------------------------------
var ambiance_courante: StringName = &""
var _lecteurs_sons: Array[AudioStreamPlayer] = []
var _prochain_lecteur: int = 0
var _lecteur_ambiance: AudioStreamPlayer = null
var _lecteur_texte: AudioStreamPlayer = null

func _ready() -> void:
	_charger_catalogues()
	_preparer_musique()
	_preparer_sons()

# =============================================================================
# Musique
# =============================================================================
func _preparer_musique() -> void:
	_lecteur_musique = AudioStreamPlayer.new()
	_lecteur_musique.name = "Musique"
	_lecteur_musique.volume_db = VOLUME_MUSIQUE_DB
	# La musique continue pendant les menus et les changements de scene.
	_lecteur_musique.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_lecteur_musique)

## Lance une piste de MUSIQUES, en boucle. Redemander celle qui joue deja ne
## la recommence pas : on peut l'appeler sans y penser dans chaque _ready().
## Dans un navigateur, le son ne demarre qu'apres la premiere touche du joueur ;
## c'est pour cela que l'ecran titre attend une entree avant d'appeler ceci.
func jouer_musique(id: StringName) -> void:
	if _lecteur_musique == null:
		return
	if id == musique_courante and _lecteur_musique.playing:
		return
	if not MUSIQUES.has(id):
		push_warning("Musique inconnue : %s" % id)
		return
	var piste: AudioStream = load(MUSIQUES[id])
	if piste == null:
		push_warning("Musique introuvable : %s" % MUSIQUES[id])
		return
	if piste is AudioStreamOggVorbis:
		piste.loop = true
	musique_courante = id
	if _lecteur_musique.playing:
		_enchainer(piste)
	else:
		_lecteur_musique.stream = piste
		_lecteur_musique.volume_db = VOLUME_MUSIQUE_DB
		_lecteur_musique.play()

## Coupe la musique en douceur.
func arreter_musique() -> void:
	if _lecteur_musique == null or not _lecteur_musique.playing:
		return
	musique_courante = &""
	_tuer_fondu()
	_fondu = create_tween()
	_fondu.tween_property(_lecteur_musique, "volume_db", VOLUME_SILENCE_DB, DUREE_FONDU)
	_fondu.tween_callback(_lecteur_musique.stop)

## Baisse la piste en cours, met la suivante, puis remonte le volume.
func _enchainer(piste: AudioStream) -> void:
	_tuer_fondu()
	_fondu = create_tween()
	_fondu.tween_property(_lecteur_musique, "volume_db", VOLUME_SILENCE_DB, DUREE_FONDU)
	_fondu.tween_callback(_changer_piste.bind(piste))
	_fondu.tween_property(_lecteur_musique, "volume_db", VOLUME_MUSIQUE_DB, DUREE_FONDU)

func _changer_piste(piste: AudioStream) -> void:
	_lecteur_musique.stream = piste
	_lecteur_musique.play()

func _tuer_fondu() -> void:
	if _fondu != null and _fondu.is_valid():
		_fondu.kill()
	_fondu = null

## A la fermeture du jeu, on arrete la piste et on la lache.
## Godot signale quand meme « resources still in use at exit » : c'est le
## serveur audio qui garde la lecture en cours jusqu'apres le menage, pas une
## fuite du jeu. Le message n'apparait qu'en quittant.
func _exit_tree() -> void:
	_tuer_fondu()
	if _lecteur_musique != null:
		_lecteur_musique.stop()
		_lecteur_musique.stream = null
	for lecteur in _lecteurs_sons:
		lecteur.stop()
		lecteur.stream = null
	for lecteur in [_lecteur_ambiance, _lecteur_texte]:
		if lecteur != null:
			lecteur.stop()
			lecteur.stream = null

# =============================================================================
# Bruitages et ambiance
# =============================================================================
func _preparer_sons() -> void:
	for i in LECTEURS_SONS:
		_lecteurs_sons.append(_fabriquer_lecteur("Son%d" % i, VOLUME_SONS_DB))
	_lecteur_ambiance = _fabriquer_lecteur("Ambiance", VOLUME_AMBIANCE_DB)
	_lecteur_texte = _fabriquer_lecteur("Texte", VOLUME_TEXTE_DB)

func _fabriquer_lecteur(nom: String, volume_db: float) -> AudioStreamPlayer:
	var lecteur := AudioStreamPlayer.new()
	lecteur.name = nom
	lecteur.volume_db = volume_db
	# Les sons continuent pendant les menus et les changements de scene.
	lecteur.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(lecteur)
	return lecteur

## Joue un bruitage de SONS. Plusieurs peuvent se chevaucher ; au-dela de
## LECTEURS_SONS, le plus ancien laisse sa place.
func jouer_son(id: StringName, volume_db: float = VOLUME_SONS_DB) -> void:
	if _lecteurs_sons.is_empty():
		return
	if not SONS.has(id):
		push_warning("Son inconnu : %s" % id)
		return
	var piste: AudioStream = load(SONS[id])
	if piste == null:
		push_warning("Son introuvable : %s" % SONS[id])
		return
	var lecteur := _lecteur_libre()
	lecteur.stream = piste
	lecteur.volume_db = volume_db
	lecteur.play()

func _lecteur_libre() -> AudioStreamPlayer:
	for lecteur in _lecteurs_sons:
		if not lecteur.playing:
			return lecteur
	# Tous occupes : on recycle a tour de role, pour ne pas toujours couper
	# le meme son.
	var recycle := _lecteurs_sons[_prochain_lecteur]
	_prochain_lecteur = (_prochain_lecteur + 1) % _lecteurs_sons.size()
	return recycle

## Pose l'ambiance d'une zone, en boucle, sous la musique. Redemander celle
## qui tourne deja ne la recommence pas.
func jouer_ambiance(id: StringName) -> void:
	if _lecteur_ambiance == null:
		return
	if id == ambiance_courante and _lecteur_ambiance.playing:
		return
	if not BOUCLES.has(id):
		push_warning("Ambiance inconnue : %s" % id)
		return
	var piste: AudioStream = load(BOUCLES[id])
	if piste == null:
		return
	if piste is AudioStreamOggVorbis:
		piste.loop = true
	ambiance_courante = id
	_lecteur_ambiance.stream = piste
	_lecteur_ambiance.volume_db = VOLUME_AMBIANCE_DB
	_lecteur_ambiance.play()

func arreter_ambiance() -> void:
	ambiance_courante = &""
	if _lecteur_ambiance != null:
		_lecteur_ambiance.stop()

## La machine a ecrire de la boite de dialogue : une boucle qui tourne tant
## que le texte s'ecrit. A arreter des que la page est posee.
func demarrer_son_texte() -> void:
	if _lecteur_texte == null or _lecteur_texte.playing:
		return
	var piste: AudioStream = load(BOUCLES[&"texte"])
	if piste == null:
		return
	if piste is AudioStreamOggVorbis:
		piste.loop = true
	_lecteur_texte.stream = piste
	_lecteur_texte.play()

func arreter_son_texte() -> void:
	if _lecteur_texte != null:
		_lecteur_texte.stop()

# =============================================================================
# Catalogues
# =============================================================================
func _charger_catalogues() -> void:
	catalogue_attaques = _charger_dossier("res://data/moves")
	catalogue_objets = _charger_dossier("res://data/items")
	catalogue_gones = _charger_dossier("res://data/gones")

func _charger_dossier(chemin: String) -> Dictionary:
	var resultat: Dictionary = {}
	var dossier := DirAccess.open(chemin)
	if dossier == null:
		push_warning("Dossier de données introuvable : %s" % chemin)
		return resultat
	for fichier in dossier.get_files():
		# En export, Godot peut renommer les .tres en .tres.remap.
		if fichier.ends_with(".remap"):
			fichier = fichier.trim_suffix(".remap")
		if not fichier.ends_with(".tres"):
			continue
		var res: Resource = ResourceLoader.load(chemin.path_join(fichier))
		if res == null:
			push_warning("Ressource illisible : %s" % fichier)
			continue
		var id := StringName(str(res.get("id")))
		if id == &"":
			id = StringName(fichier.get_basename())
		resultat[id] = res
	return resultat

## Les Gones qui ont le droit d'apparaître : consentement reçu, ou Gone générique.
func gones_jouables() -> Array:
	var liste: Array = []
	for fiche in catalogue_gones.values():
		if fiche.consentement_recu or String(fiche.id).begins_with("generique"):
			liste.append(fiche)
	return liste

func gones_sauvages() -> Array:
	var liste: Array = []
	for fiche in gones_jouables():
		if fiche.sauvage:
			liste.append(fiche)
	return liste

# =============================================================================
# Partie
# =============================================================================
func nouvelle_partie() -> void:
	equipe.clear()
	inventaire = {&"filet_a_gone": 5, &"mache_praline": 2}
	note_de_frais = 120
	drapeaux.clear()
	bienveillance = 0
	zone_courante = &"perrache"
	case_joueur = Zones.zone(&"perrache")["depart"]
	partie_commencee = true

	var depart: GoneData = catalogue_gones.get(&"thigoat")
	if depart == null:
		var dispo := gones_jouables()
		depart = dispo[0] if not dispo.is_empty() else null
	if depart != null:
		equipe.append(GoneInstance.new(depart, 5))

	equipe_modifiee.emit()
	inventaire_modifie.emit()
	note_de_frais_modifiee.emit()

## Fait bouger la Bienveillance. Le detail sert au journal, pas au joueur :
## le compteur reste cache, c'est ce qui l'empeche d'etre optimise.
func ajuster_bienveillance(variation: int, raison: String = "") -> void:
	bienveillance = clampi(bienveillance + variation, -20, 20)
	if raison != "":
		print("[bienveillance] %+d (%s) -> %d" % [variation, raison, bienveillance])

## Strictement positif : les alternants restent. Sinon ils passent freelance.
func fin_bienveillante() -> bool:
	return bienveillance > 0

## Le patron qu'on n'a pas choisi : c'est lui le rival.
func rival() -> StringName:
	return &"moustachette" if heros == &"moustache" else &"moustache"

func fiche_heros() -> Dictionary:
	return HEROS.get(heros, HEROS[&"moustache"])

func fiche_rival() -> Dictionary:
	return HEROS.get(rival(), HEROS[&"moustachette"])

## Bonus de Moustache : il sait faire signer. Multiplie la chance de recrutement.
func bonus_recrutement() -> float:
	return 1.10 if heros == &"moustache" else 1.0

## Bonus de Moustachette : elle fait monter en competences. Ses alternants
## continuent de progresser une marche plus haut que les autres.
func marge_de_niveau() -> int:
	return 4 if heros == &"moustachette" else 3

## Garde-fou : permet de lancer scenes/battle/battle.tscn seule (F6) sans crash.
func assurer_partie() -> void:
	if not partie_commencee or equipe.is_empty():
		nouvelle_partie()

# =============================================================================
# Équipe
# =============================================================================
func equipe_est_pleine() -> bool:
	return equipe.size() >= TAILLE_EQUIPE_MAX

func ajouter_a_equipe(gone: GoneInstance) -> bool:
	if equipe_est_pleine():
		return false
	equipe.append(gone)
	equipe_modifiee.emit()
	return true

func premier_gone_valide() -> GoneInstance:
	for g in equipe:
		if not g.est_ko():
			return g
	return null

func equipe_hors_combat() -> bool:
	return premier_gone_valide() == null

func soigner_equipe() -> void:
	for g in equipe:
		g.soigner_tout()
	equipe_modifiee.emit()

# =============================================================================
# Inventaire et note de frais
# =============================================================================
func quantite_objet(id: StringName) -> int:
	return int(inventaire.get(id, 0))

func ajouter_objet(id: StringName, nombre: int = 1) -> void:
	inventaire[id] = quantite_objet(id) + nombre
	inventaire_modifie.emit()

func consommer_objet(id: StringName) -> bool:
	if quantite_objet(id) <= 0:
		return false
	inventaire[id] = quantite_objet(id) - 1
	if inventaire[id] <= 0:
		inventaire.erase(id)
	inventaire_modifie.emit()
	return true

func objets_possedes() -> Array:
	var liste: Array = []
	for id in inventaire:
		var objet: ItemData = catalogue_objets.get(id)
		if objet != null and quantite_objet(id) > 0:
			liste.append(objet)
	return liste

func ajouter_note_de_frais(montant: int) -> void:
	note_de_frais = maxi(0, note_de_frais + montant)
	note_de_frais_modifiee.emit()

func depenser_note_de_frais(montant: int) -> bool:
	if note_de_frais < montant:
		return false
	note_de_frais -= montant
	note_de_frais_modifiee.emit()
	return true

## Le prix d'un objet en boutique, 0 s'il n'y est pas vendu.
func prix(id: StringName) -> int:
	return int(BOUTIQUE.get(id, 0))

## La difficulte d'un mini-jeu suit le stade de l'alternant entraine : un
## Chomeur s'entraine doucement, un Alternant encaisse le niveau 3.
func niveau_minijeu(alternant: GoneInstance) -> int:
	return clampi(alternant.stade() + 1, 1, 3) if alternant != null else 1

# =============================================================================
# Drapeaux de progression
# =============================================================================
func drapeau(nom: StringName) -> bool:
	return bool(drapeaux.get(nom, false))

func lever_drapeau(nom: StringName) -> void:
	drapeaux[nom] = true

# =============================================================================
# Sauvegarde
# =============================================================================
func sauvegarde_existe() -> bool:
	return FileAccess.file_exists(CHEMIN_SAUVEGARDE)

## Sauvegarde silencieuse, aux moments ou le joueur en a besoin sans y penser.
## Dans un navigateur, fermer l'onglet ne previent pas : compter sur le menu
## pause, c'est perdre la partie de quelqu'un.
func sauvegarde_auto() -> void:
	if partie_commencee:
		sauvegarder()

func sauvegarder() -> bool:
	var equipe_brute: Array = []
	for g in equipe:
		equipe_brute.append(g.to_dict())
	var inv: Dictionary = {}
	for id in inventaire:
		inv[String(id)] = inventaire[id]
	var dra: Dictionary = {}
	for id in drapeaux:
		dra[String(id)] = drapeaux[id]

	var donnees := {
		"version": 1,
		"equipe": equipe_brute,
		"inventaire": inv,
		"note_de_frais": note_de_frais,
		"drapeaux": dra,
		"heros": String(heros),
		"bienveillance": bienveillance,
		"zone": String(zone_courante),
		"case_x": case_joueur.x,
		"case_y": case_joueur.y,
	}
	var fichier := FileAccess.open(CHEMIN_SAUVEGARDE, FileAccess.WRITE)
	if fichier == null:
		push_error("Sauvegarde impossible : %s" % error_string(FileAccess.get_open_error()))
		return false
	fichier.store_string(JSON.stringify(donnees, "\t"))
	fichier.close()
	return true

func charger() -> bool:
	if not sauvegarde_existe():
		return false
	var fichier := FileAccess.open(CHEMIN_SAUVEGARDE, FileAccess.READ)
	if fichier == null:
		return false
	var brut: Variant = JSON.parse_string(fichier.get_as_text())
	fichier.close()
	if typeof(brut) != TYPE_DICTIONARY:
		push_error("Sauvegarde illisible, nouvelle partie.")
		return false

	var donnees: Dictionary = brut
	equipe.clear()
	for d in donnees.get("equipe", []):
		var g := GoneInstance.from_dict(d, catalogue_gones)
		if g.data != null:
			equipe.append(g)

	inventaire.clear()
	for id in donnees.get("inventaire", {}):
		inventaire[StringName(id)] = int(donnees["inventaire"][id])
	note_de_frais = int(donnees.get("note_de_frais", 0))
	drapeaux.clear()
	for id in donnees.get("drapeaux", {}):
		drapeaux[StringName(id)] = bool(donnees["drapeaux"][id])

	heros = StringName(donnees.get("heros", "moustache"))
	bienveillance = int(donnees.get("bienveillance", 0))
	zone_courante = StringName(donnees.get("zone", "perrache"))
	case_joueur = Vector2i(int(donnees.get("case_x", 12)), int(donnees.get("case_y", 10)))
	partie_commencee = true

	equipe_modifiee.emit()
	inventaire_modifie.emit()
	note_de_frais_modifiee.emit()
	return true

func effacer_sauvegarde() -> void:
	if sauvegarde_existe():
		DirAccess.remove_absolute(CHEMIN_SAUVEGARDE)
