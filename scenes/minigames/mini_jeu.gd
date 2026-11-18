class_name MiniJeu
extends Node2D
## Base commune des mini-jeux d'entrainement (Rythme, Frappe chronometree).
##
## Elle gere le deroule, identique pour tous :
##   CONSIGNES  ecran qui explique le but, les touches et la difficulte ;
##   DECOMPTE   3, 2, 1, c'est parti ;
##   JEU        le mini-jeu lui-meme (les methodes _jeu_* des scripts enfants) ;
##   FIN        le resultat, le gain reellement accorde, retour a la carte.
## Elle pose aussi l'alternant entraine a l'ecran (il frappe quand on reussit) et
## les petits messages qui s'envolent (« Parfait ! »).
##
## Un mini-jeu enfant definit : _consignes(), _touches(), _commencer(),
## _jeu_process(delta), _jeu_input(event), _jeu_draw() et _calculer_gain().
## La difficulte (1 a 5) suit le niveau de l'alternant : GameState.niveau_minijeu.

enum Etape { CONSIGNES, DECOMPTE, JEU, FIN }

const DUREE_DECOMPTE := 0.7         # secondes par chiffre
const DUREE_MESSAGE := 0.8          # duree de vie d'un message qui s'envole
const ECHELLE_PERSO := 0.75
const TAILLE_GROS := 16
const LARGEUR_PANNEAU := 0.86       # part de la largeur de l'ecran
const MARGE_PANNEAU := 16.0

var gone: GoneInstance
var difficulte: int = 1
var etape: Etape = Etape.CONSIGNES

var _decompte: float = 0.0
var _messages: Array = []           # [{"texte", "couleur", "position", "age"}]
var _perso: AnimatedSprite2D
var _panneau: PanelContainer
var _police: Font

@onready var _titre: Label = %Titre
@onready var _info: Label = %Info
@onready var _resultat: Label = %Resultat

func _ready() -> void:
	GameState.assurer_partie()
	if GameState.equipe.is_empty():
		_retour()
		return
	var index := clampi(GameState.gone_a_entrainer, 0, GameState.equipe.size() - 1)
	gone = GameState.equipe[index]
	difficulte = GameState.niveau_minijeu(gone)
	_police = _titre.get_theme_font(&"font")
	_poser_perso()
	_titre.text = ""
	_info.text = ""
	_resultat.text = ""
	_montrer_consignes()

# =============================================================================
# A definir dans chaque mini-jeu
# =============================================================================
## [titre, stat entrainee (texte), but (une ou deux phrases)]
func _consignes() -> Array:
	return ["", "", ""]

## Les touches et ce qu'elles font : [[["←", "↓"], "frapper la note"], ...]
func _touches() -> Array:
	return []

func _commencer() -> void:
	pass

func _jeu_process(_delta: float) -> void:
	pass

func _jeu_input(_event: InputEvent) -> void:
	pass

func _jeu_draw() -> void:
	pass

## [stat (StringName), gain brut, ligne de score affichee]
func _calculer_gain() -> Array:
	return [&"", 0, ""]

## Position de l'alternant a l'ecran (pieds), a adapter si besoin.
func _position_perso() -> Vector2:
	var ecran := get_viewport_rect().size
	return Vector2(ecran.x * 0.14, ecran.y * 0.78)

# =============================================================================
# Deroule
# =============================================================================
func _process(delta: float) -> void:
	for m: Dictionary in _messages:
		m["age"] = float(m["age"]) + delta
	_messages = _messages.filter(func(m: Dictionary) -> bool: return float(m["age"]) < DUREE_MESSAGE)
	match etape:
		Etape.DECOMPTE:
			_decompte -= delta
			if _decompte <= 0.0:
				etape = Etape.JEU
				_info.text = ""
		Etape.JEU:
			_jeu_process(delta)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	match etape:
		Etape.CONSIGNES:
			if event.is_action_pressed("ui_accept"):
				_fermer_panneau()
				_commencer()
				etape = Etape.DECOMPTE
				_decompte = DUREE_DECOMPTE * 3.0
				GameState.jouer_son(&"dialogue_suivant")
			elif event.is_action_pressed("ui_cancel"):
				_retour()
		Etape.JEU:
			_jeu_input(event)
		Etape.FIN:
			if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
				_retour()

## A appeler par le mini-jeu quand la partie est finie.
func terminer() -> void:
	etape = Etape.FIN
	var resultat := _calculer_gain()
	var stat: StringName = resultat[0]
	var gain: int = resultat[1]
	var lignes: Array = [str(resultat[2])]
	var nom_stat := "attaque" if stat == &"attaque" else "vitesse"
	if gain > 0:
		var accorde := gone.appliquer_entrainement(stat, gain)
		if accorde > 0:
			GameState.jouer_son(&"niveau_gagne")
			GameState.equipe_modifiee.emit()
			lignes.append("%s gagne +%d en %s !" % [gone.nom(), accorde, nom_stat])
			lignes.append("%s %d  (bonus +%d/%d)" % [
				"ATT" if stat == &"attaque" else "VIT", gone.call(String(stat)),
				gone.bonus_de(stat), GoneInstance.BONUS_MAX])
			jouer_perso(&"combat_poing")
		else:
			lignes.append("%s a atteint son plafond en %s (+%d)." % [gone.nom(), nom_stat, GoneInstance.BONUS_MAX])
	else:
		lignes.append("Pas assez pour progresser cette fois.")
		jouer_perso(&"combat_touche")
	_montrer_panneau("Résultat", lignes, "Entrée : revenir à la carte")

func _retour() -> void:
	get_tree().change_scene_to_file(GameState.SCENE_MONDE)

# =============================================================================
# Ecrans de consignes et de resultat
# =============================================================================
func _montrer_consignes() -> void:
	var c := _consignes()
	var lignes: Array = [str(c[2]), ""]
	var panneau := _montrer_panneau(str(c[0]), lignes, "Entrée : commencer     Échap : retour")
	var boite: VBoxContainer = panneau.get_child(0)
	# les touches, dessinees comme des touches de clavier
	var position_touches := boite.get_child_count() - 1
	for consigne: Array in _touches():
		var rangee := HBoxContainer.new()
		for touche: String in consigne[0]:
			rangee.add_child(_touche(touche))
		rangee.add_child(_texte(str(consigne[1]), PaletteUi.TEXTE))
		boite.add_child(rangee)
		boite.move_child(rangee, position_touches)
		position_touches += 1
	var info := _texte("Entraîne : %s     Difficulté %d/%d (%s Niv.%d)" % [
		c[1], difficulte, GameState.DIFFICULTE_MINIJEU_MAX, gone.nom(), gone.niveau], PaletteUi.TEXTE_DOUX)
	boite.add_child(info)
	boite.move_child(info, position_touches)

## Un panneau centre : titre, lignes de texte, et une ligne d'aide en bas.
func _montrer_panneau(titre: String, lignes: Array, aide: String) -> PanelContainer:
	_fermer_panneau()
	var ecran := get_viewport_rect().size
	_panneau = PanelContainer.new()
	var largeur := ecran.x * LARGEUR_PANNEAU
	_panneau.custom_minimum_size = Vector2(largeur, 0)
	var boite := VBoxContainer.new()
	_panneau.add_child(boite)
	boite.add_child(_texte(titre, PaletteUi.ACCENT))
	for ligne in lignes:
		var l := _texte(str(ligne), PaletteUi.TEXTE, true)
		# un texte a la ligne doit connaitre sa largeur, sinon il s'etire en hauteur
		l.custom_minimum_size.x = largeur - MARGE_PANNEAU
		boite.add_child(l)
	boite.add_child(_texte(aide, PaletteUi.TEXTE_DOUX))
	_titre.get_parent().add_child(_panneau)
	# centre une fois la taille connue
	_panneau.reset_size()
	_panneau.position = (ecran - _panneau.get_combined_minimum_size()) * 0.5
	return _panneau

func _fermer_panneau() -> void:
	if _panneau != null:
		_panneau.queue_free()
		_panneau = null

func _texte(texte: String, couleur: Color, retour_ligne: bool = false) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_color_override("font_color", couleur)
	if retour_ligne:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

## Une touche de clavier : un petit cadre avec son nom.
func _touche(nom: String) -> PanelContainer:
	var cadre := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PaletteUi.PANNEAU
	style.border_color = PaletteUi.ACCENT
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 3
	style.content_margin_right = 3
	cadre.add_theme_stylebox_override("panel", style)
	cadre.add_child(_texte(nom, PaletteUi.ACCENT))
	return cadre

# =============================================================================
# L'alternant entraine et les messages
# =============================================================================
func _poser_perso() -> void:
	var planche: SpriteFrames = gone.data.frames if gone.data != null else null
	if planche == null:
		return
	_perso = AnimatedSprite2D.new()
	_perso.sprite_frames = planche
	_perso.scale = Vector2.ONE * ECHELLE_PERSO
	_perso.centered = true
	add_child(_perso)
	var hauteur := float(planche.get_frame_texture(&"idle_down", 0).get_height()) if planche.has_animation(&"idle_down") else 56.0
	_perso.position = _position_perso() - Vector2(0, hauteur * ECHELLE_PERSO * 0.5)
	_perso.animation_finished.connect(_perso_au_repos)
	_perso_au_repos()

func _perso_au_repos() -> void:
	if _perso == null:
		return
	var repos := &"idle_right" if _perso.sprite_frames.has_animation(&"idle_right") else &"idle_down"
	_perso.play(repos)

## Joue une animation de combat (combat_poing, combat_pied, combat_touche) si
## l'alternant l'a, puis le remet au repos.
func jouer_perso(animation: StringName) -> void:
	if _perso != null and _perso.sprite_frames.has_animation(animation):
		_perso.play(animation)

## Un petit texte qui monte et s'efface (« Parfait ! », « +3 »).
func message(texte: String, couleur: Color, position_ecran: Vector2) -> void:
	_messages.append({"texte": texte, "couleur": couleur, "position": position_ecran, "age": 0.0})

func _draw() -> void:
	var ecran := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, ecran), PaletteUi.FOND)
	_jeu_draw()
	for m: Dictionary in _messages:
		var age: float = m["age"]
		var couleur: Color = m["couleur"]
		couleur.a = 1.0 - age / DUREE_MESSAGE
		var p: Vector2 = m["position"] - Vector2(0, age * 20.0)
		_ecrire(str(m["texte"]), p, couleur, 8, true)
	if etape == Etape.DECOMPTE:
		var chiffre := ceili(_decompte / DUREE_DECOMPTE)
		_ecrire(str(chiffre) if chiffre > 0 else "Go !", ecran * 0.5, PaletteUi.ACCENT, TAILLE_GROS, true)

## Ecrit un texte, centre sur `position` si `centre`.
func _ecrire(texte: String, position_ecran: Vector2, couleur: Color, taille: int, centre: bool = false) -> void:
	if _police == null:
		return
	var p := position_ecran
	if centre:
		var largeur := _police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille).x
		p.x -= largeur * 0.5
	draw_string(_police, p, texte, HORIZONTAL_ALIGNMENT_LEFT, -1, taille, couleur)
