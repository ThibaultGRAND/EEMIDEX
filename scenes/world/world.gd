extends Node2D
## La carte. Déplacement case par case, rencontres dans l'herbe, traboules,
## ressources à ramasser, hub de soin, boutique et salle d'entraînement.
##
## Les cases sont dessinées à la main dans _draw() : c'est un placeholder.
## Quand les tilesets seront prêts, remplacer _draw() par une TileMapLayer.

enum Mode { LIBRE, MENU }

const DELAI_DEPLACEMENT := 0.13
const CHANCE_RENCONTRE := 0.14

var zone_id: StringName = &"presquile"
var zone: Dictionary = {}
var pos: Vector2i = Vector2i(3, 5)

var _mode: Mode = Mode.LIBRE
var _cooldown: float = 0.0
var _menu_contexte: StringName = &""
var _menu_titre: String = ""
var _menu_options: Array = []
var _menu_index: int = 0
var _minijeu_choisi: StringName = &""

@onready var _label_zone: Label = %Zone
@onready var _label_message: Label = %Message
@onready var _volet: ColorRect = %Volet
@onready var _overlay: Label = %Overlay

func _ready() -> void:
	GameState.assurer_partie()
	_charger_zone(GameState.zone_courante, GameState.case_joueur)
	if GameState.dernier_resultat_combat != "":
		_message(GameState.dernier_resultat_combat)
		GameState.dernier_resultat_combat = ""
	else:
		_message(_indice_case(_case_courante()))

func _charger_zone(id: StringName, case_depart: Vector2i) -> void:
	zone_id = id
	zone = Zones.zone(id)
	pos = case_depart
	GameState.zone_courante = id
	GameState.case_joueur = pos
	_label_zone.text = str(zone["titre"])
	queue_redraw()

# =============================================================================
# Déplacement
# =============================================================================
func _process(delta: float) -> void:
	if _mode != Mode.LIBRE:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	var direction := Vector2i.ZERO
	if Input.is_action_pressed("ui_up"):
		direction = Vector2i(0, -1)
	elif Input.is_action_pressed("ui_down"):
		direction = Vector2i(0, 1)
	elif Input.is_action_pressed("ui_left"):
		direction = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_right"):
		direction = Vector2i(1, 0)
	if direction != Vector2i.ZERO:
		_deplacer(direction)
		_cooldown = DELAI_DEPLACEMENT

func _deplacer(direction: Vector2i) -> void:
	var cible := pos + direction
	if not Zones.est_traversable(zone_id, cible):
		return
	pos = cible
	GameState.case_joueur = pos
	queue_redraw()
	_entrer_sur_case()

func _case_courante() -> String:
	return Zones.case_a(zone_id, pos)

func _entrer_sur_case() -> void:
	var c := _case_courante()
	var sorties: Dictionary = zone["sorties"]
	if sorties.has(c):
		var sortie: Array = sorties[c]
		_charger_zone(StringName(sortie[0]), Vector2i(int(sortie[1]), int(sortie[2])))
		_message("Vous arrivez : %s" % zone["titre"])
		return
	match c:
		"T":
			pos = Zones.autre_traboule(zone_id, pos)
			GameState.case_joueur = pos
			queue_redraw()
			_message("Traboule : un raccourci entre deux cours.")
		"R":
			_ramasser_ressource()
		"g":
			_tenter_rencontre()
		_:
			_message(_indice_case(c))

func _indice_case(c: String) -> String:
	match c:
		"S":
			return "Soins. Entrée pour remettre l'équipe d'aplomb."
		"B":
			return "Boutique. Entrée pour échanger des ressources."
		"M":
			return "Entraînement. Entrée pour lancer un mini-jeu."
		"X":
			return "Quelqu'un garde la colline. Entrée pour l'affronter."
		"g":
			return "Ça bouge dans les fourrés..."
		_:
			return "Échap : menu     Entrée : agir"

# =============================================================================
# Ressources et rencontres
# =============================================================================
func _ramasser_ressource() -> void:
	var cle := StringName("ramasse_%s_%d_%d" % [zone_id, pos.x, pos.y])
	if GameState.drapeau(cle):
		_message("Il n'y a plus rien ici.")
		return
	var ressource: StringName = zone["ressource"]
	GameState.lever_drapeau(cle)
	GameState.ajouter_ressource(ressource, 2)
	_message("+2 %s (total : %d)" % [
		GameState.RESSOURCES.get(ressource, ressource),
		GameState.quantite_ressource(ressource),
	])

func _tenter_rencontre() -> void:
	if randf() > CHANCE_RENCONTRE:
		_message("Ça bouge dans les fourrés...")
		return
	var candidats: Array = []
	for id in zone["rencontres"]:
		var fiche: GoneData = GameState.catalogue_gones.get(id)
		if fiche != null and fiche in GameState.gones_sauvages():
			candidats.append(fiche)
	if candidats.is_empty():
		candidats = GameState.gones_sauvages()
	if candidats.is_empty():
		return
	GameState.rencontre_en_attente = candidats[randi() % candidats.size()]
	GameState.niveau_rencontre = randi_range(int(zone["niveau_min"]), int(zone["niveau_max"]))
	GameState.combat_est_boss = false
	get_tree().change_scene_to_file(GameState.SCENE_COMBAT)

func _lancer_combat_de_fin() -> void:
	if GameState.drapeau(&"gardien_battu"):
		_message("La colline est calme. Fin du MVP : merci d'avoir joué.")
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
	elif event.is_action_pressed("ui_accept"):
		_interagir()

func _interagir() -> void:
	match _case_courante():
		"S":
			GameState.soigner_equipe()
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
			_message(_indice_case(_case_courante()))

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
	var noms: Array[String] = []
	for g in GameState.equipe:
		noms.append("%s  Niv.%d" % [g.nom(), g.niveau])
	noms.append("Annuler")
	_ouvrir_menu(&"choix_gone", "Entraîner qui ?", noms)

func _lancer_minijeu(index: int) -> void:
	if index < 0 or index >= GameState.equipe.size():
		_fermer_menu()
		return
	GameState.gone_a_entrainer = index
	var scene := GameState.SCENE_RYTHME if _minijeu_choisi == &"rythme" else GameState.SCENE_FRAPPE
	get_tree().change_scene_to_file(scene)

func _texte_equipe() -> String:
	var lignes: Array[String] = ["Équipe (%d/%d)" % [GameState.equipe.size(), GameState.TAILLE_EQUIPE_MAX]]
	for g in GameState.equipe:
		lignes.append("%s  Niv.%d  PV %d/%d" % [g.nom(), g.niveau, g.pv, g.pv_max()])
		lignes.append("   ATT %d  DEF %d  VIT %d" % [g.attaque(), g.defense(), g.vitesse()])
	lignes.append("")
	var sacs: Array[String] = []
	for objet in GameState.objets_possedes():
		sacs.append("%s x%d" % [objet.display_name, GameState.quantite_objet(objet.id)])
	lignes.append("Sac : " + (", ".join(sacs) if not sacs.is_empty() else "vide"))
	return "\n".join(lignes)

func _texte_boutique() -> String:
	var lignes: Array[String] = ["Boutique"]
	for id in GameState.RESSOURCES:
		lignes.append("%s : %d" % [GameState.RESSOURCES[id], GameState.quantite_ressource(id)])
	return "\n".join(lignes)

func _message(texte: String) -> void:
	_label_message.text = texte

# =============================================================================
# Rendu (placeholder : à remplacer par une TileMapLayer)
# =============================================================================
func _draw() -> void:
	var t := Zones.TAILLE_CASE
	var plan: Array = zone["plan"]
	var sol: Color = zone["sol"]
	for y in plan.size():
		var ligne: String = plan[y]
		for x in ligne.length():
			var rect := Rect2(x * t, y * t, t, t)
			var c: String = ligne[x]
			draw_rect(rect, sol if c != "#" else Color(0.145098, 0.168627, 0.223529))
			_dessiner_decor(c, Vector2(x * t, y * t), t)
	_dessiner_joueur(Vector2(pos.x * t, pos.y * t), t)

func _dessiner_decor(c: String, origine: Vector2, t: int) -> void:
	match c:
		"g":
			draw_rect(Rect2(origine + Vector2(1, 1), Vector2(t - 2, t - 2)), Color(0.231373, 0.431373, 0.286275))
			draw_rect(Rect2(origine + Vector2(4, 4), Vector2(2, 6)), Color(0.321569, 0.552941, 0.364706))
			draw_rect(Rect2(origine + Vector2(10, 6), Vector2(2, 6)), Color(0.321569, 0.552941, 0.364706))
		"S":
			draw_rect(Rect2(origine + Vector2(2, 2), Vector2(12, 12)), Color(0.862745, 0.345098, 0.345098))
			draw_rect(Rect2(origine + Vector2(7, 4), Vector2(2, 8)), Color(1, 1, 1))
			draw_rect(Rect2(origine + Vector2(4, 7), Vector2(8, 2)), Color(1, 1, 1))
		"B":
			draw_rect(Rect2(origine + Vector2(2, 2), Vector2(12, 12)), Color(0.286275, 0.513726, 0.776471))
			draw_rect(Rect2(origine + Vector2(4, 6), Vector2(8, 5)), Color(0.941176, 0.941176, 0.886275))
		"M":
			draw_rect(Rect2(origine + Vector2(2, 2), Vector2(12, 12)), Color(0.52549, 0.4, 0.72549))
			draw_rect(Rect2(origine + Vector2(5, 5), Vector2(6, 6)), Color(0.937255, 0.835294, 0.513726))
		"T":
			draw_rect(Rect2(origine + Vector2(3, 0), Vector2(10, 16)), Color(0.105882, 0.0941176, 0.133333))
			draw_rect(Rect2(origine + Vector2(5, 3), Vector2(6, 13)), Color(0.054902, 0.0470588, 0.0745098))
		"R":
			draw_rect(Rect2(origine + Vector2(5, 6), Vector2(6, 6)), Color(0.937255, 0.741176, 0.329412))
			draw_rect(Rect2(origine + Vector2(7, 4), Vector2(2, 3)), Color(0.72549, 0.521569, 0.223529))
		"X":
			draw_rect(Rect2(origine + Vector2(3, 1), Vector2(10, 14)), Color(0.882353, 0.858824, 0.788235))
			draw_rect(Rect2(origine + Vector2(6, 5), Vector2(4, 10)), Color(0.580392, 0.552941, 0.470588))
		"#":
			draw_rect(Rect2(origine + Vector2(0, 0), Vector2(t, 3)), Color(0.219608, 0.254902, 0.333333))
		_:
			if c.is_valid_int():
				draw_rect(Rect2(origine + Vector2(0, 0), Vector2(t, t)), Color(0.396078, 0.419608, 0.364706))
				draw_rect(Rect2(origine + Vector2(6, 2), Vector2(4, 12)), Color(0.760784, 0.780392, 0.686275))

func _dessiner_joueur(origine: Vector2, _t: int) -> void:
	draw_rect(Rect2(origine + Vector2(4, 7), Vector2(8, 8)), Color(0.286275, 0.360784, 0.541176))
	draw_rect(Rect2(origine + Vector2(4, 2), Vector2(8, 6)), Color(0.960784, 0.819608, 0.670588))
	draw_rect(Rect2(origine + Vector2(3, 1), Vector2(10, 3)), Color(0.682353, 0.270588, 0.247059))
	draw_rect(Rect2(origine + Vector2(5, 6), Vector2(6, 1)), Color(0.164706, 0.133333, 0.117647))
