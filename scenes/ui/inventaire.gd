class_name Inventaire
extends Control
## L'inventaire : l'equipe et le sac, ouverts depuis le menu pause (world.gd).
## A gauche la liste (onglets Equipe / Sac), a droite la fiche de la ligne
## selectionnee : pour un alternant, son niveau, son stade, ses jauges, ses stats
## avec le bonus gagne aux mini-jeux, et ses capacites ; pour un objet, son effet.
##
## Les noeuds sont construits ici, avec les composants communs (ListeMenu,
## FicheCombattant) et les couleurs de PaletteUi. Ouvert avec ouvrir() ; se ferme
## tout seul (Echap) et previent par le signal fermee.

signal fermee

enum Onglet { EQUIPE, SAC }

const SCENE_LISTE: PackedScene = preload("res://scenes/ui/composants/liste_menu.tscn")
const SCENE_FICHE: PackedScene = preload("res://scenes/ui/composants/fiche_combattant.tscn")
const LARGEUR_GAUCHE := 112.0
const TAILLE_PORTRAIT := Vector2(26, 34)
## Les stats et le mini-jeu qui les fait monter (vide : aucun mini-jeu).
const STATS := [
	[&"attaque", "ATT", "Frappe chronométrée"],
	[&"defense", "DEF", ""],
	[&"vitesse", "VIT", "Rythme"],
]

var _onglet: Onglet = Onglet.EQUIPE
var _liste: ListeMenu
var _titre_equipe: Label
var _titre_sac: Label
var _argent: Label
var _contenu: VBoxContainer

func _ready() -> void:
	visible = false
	_construire()

func ouvrir() -> void:
	_onglet = Onglet.EQUIPE
	visible = true
	_remplir()

func fermer() -> void:
	visible = false
	fermee.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		_onglet = Onglet.SAC if _onglet == Onglet.EQUIPE else Onglet.EQUIPE
		GameState.jouer_son(&"clic")
		_remplir()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()      # l'inventaire garde la main

# =============================================================================
# Construction
# =============================================================================
func _construire() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var fond := PanelContainer.new()
	fond.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fond)
	var colonnes := HBoxContainer.new()
	fond.add_child(colonnes)

	var gauche := VBoxContainer.new()
	gauche.custom_minimum_size.x = LARGEUR_GAUCHE
	colonnes.add_child(gauche)
	var onglets := HBoxContainer.new()
	gauche.add_child(onglets)
	_titre_equipe = _label("Équipe", PaletteUi.ACCENT)
	_titre_sac = _label("Sac", PaletteUi.TEXTE_ETEINT)
	onglets.add_child(_titre_equipe)
	onglets.add_child(_label("|", PaletteUi.TEXTE_ETEINT))
	onglets.add_child(_titre_sac)
	_liste = SCENE_LISTE.instantiate()
	_liste.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gauche.add_child(_liste)
	_liste.choix_change.connect(_sur_selection)
	_liste.annule.connect(fermer)
	_argent = _label("", PaletteUi.TEXTE_DOUX)
	gauche.add_child(_argent)
	gauche.add_child(_label("← → onglet   Échap fermer", PaletteUi.TEXTE_ETEINT))

	var droite := PanelContainer.new()
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonnes.add_child(droite)
	_contenu = VBoxContainer.new()
	droite.add_child(_contenu)

func _label(texte: String, couleur: Color, retour_ligne: bool = false) -> Label:
	var l := Label.new()
	l.text = texte
	l.add_theme_color_override("font_color", couleur)
	if retour_ligne:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 10
	return l

# =============================================================================
# Remplissage
# =============================================================================
func _remplir() -> void:
	var equipe := _onglet == Onglet.EQUIPE
	_titre_equipe.add_theme_color_override("font_color", PaletteUi.ACCENT if equipe else PaletteUi.TEXTE_ETEINT)
	_titre_sac.add_theme_color_override("font_color", PaletteUi.TEXTE_ETEINT if equipe else PaletteUi.ACCENT)
	_argent.text = "Note de frais : %d" % GameState.note_de_frais
	var options: Array = []
	if equipe:
		for i in GameState.equipe.size():
			var g: GoneInstance = GameState.equipe[i]
			options.append({"id": StringName(str(i)), "texte": g.nom(), "detail": "Niv.%d" % g.niveau})
	else:
		for objet: ItemData in GameState.objets_possedes():
			options.append({"id": objet.id, "texte": objet.display_name,
				"detail": "x%d" % GameState.quantite_objet(objet.id)})
	if options.is_empty():
		options.append({"texte": "Personne pour l'instant" if equipe else "Sac vide", "actif": false})
	_liste.definir_options(options)
	_sur_selection(_liste.index(), &"")

func _vider_fiche() -> void:
	for enfant in _contenu.get_children():
		_contenu.remove_child(enfant)
		enfant.queue_free()

func _sur_selection(index: int, _id: StringName) -> void:
	_vider_fiche()
	if _onglet == Onglet.EQUIPE:
		if index >= 0 and index < GameState.equipe.size():
			_fiche_alternant(GameState.equipe[index])
	else:
		var objets := GameState.objets_possedes()
		if index >= 0 and index < objets.size():
			_fiche_objet(objets[index])

## La fiche d'un alternant : qui il est, ou il en est, ce qu'il sait faire.
func _fiche_alternant(g: GoneInstance) -> void:
	var haut := HBoxContainer.new()
	_contenu.add_child(haut)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = TAILLE_PORTRAIT
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var planche: SpriteFrames = g.data.frames if g.data != null else null
	if planche != null and planche.has_animation(&"idle_down"):
		portrait.texture = planche.get_frame_texture(&"idle_down", 0)
	haut.add_child(portrait)
	var fiche: FicheCombattant = SCENE_FICHE.instantiate()
	fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	haut.add_child(fiche)
	fiche.depuis_gone(g)
	fiche.definir_cafe(g.cafe, g.cafe_max(), false)

	var palier := g.prochain_palier()
	var stade := g.nom_du_stade()
	stade += "  ·  évolue au Niv.%d" % palier if palier > 0 else "  ·  stade final"
	_contenu.add_child(_label(stade, PaletteUi.TEXTE_DOUX))

	for stat: Array in STATS:
		var bonus := g.bonus_de(stat[0])
		var valeur: int = g.call(String(stat[0]))
		var ligne := HBoxContainer.new()
		ligne.add_child(_label("%s %d" % [stat[1], valeur], PaletteUi.TEXTE))
		if stat[2] != "":
			ligne.add_child(_label("+%d/%d %s" % [bonus, GoneInstance.BONUS_MAX, stat[2]], PaletteUi.TEXTE_DOUX))
		elif bonus > 0:
			ligne.add_child(_label("+%d" % bonus, PaletteUi.TEXTE_DOUX))
		_contenu.add_child(ligne)

	_contenu.add_child(_label("Capacités", PaletteUi.ACCENT))
	# Le resume suffit : la description des .tres sert de note a l'equipe et ferait
	# deborder la fiche.
	for attaque: MoveData in g.attaques():
		var ligne := HBoxContainer.new()
		ligne.add_child(_label(attaque.display_name, PaletteUi.TEXTE))
		ligne.add_child(_label(_resume(attaque), PaletteUi.TEXTE_DOUX))
		_contenu.add_child(ligne)

## Ce que fait une attaque, en quelques mots : degats, effets, cout en Cafe.
func _resume(a: MoveData) -> String:
	var morceaux: Array = []
	if a.degats_max > 0:
		morceaux.append("%d-%d dégâts" % [a.degats_min, a.degats_max])
	elif a.puissance > 0:
		morceaux.append("%d dégâts" % a.puissance)
	if a.soin > 0:
		morceaux.append("soigne %d" % a.soin)
	if a.etourdit:
		morceaux.append("étourdit")
	if a.brulure_degats > 0:
		morceaux.append("brûle %d×%d" % [a.brulure_degats, a.brulure_tours])
	if a.stat_modifiee != &"" and a.modificateur != 0:
		morceaux.append("%s %+d" % [String(a.stat_modifiee).left(3).to_upper(), a.modificateur])
	if morceaux.is_empty():
		morceaux.append("soutien")
	morceaux.append("café %d" % a.cout_cafe())
	return ", ".join(morceaux)

func _fiche_objet(objet: ItemData) -> void:
	_contenu.add_child(_label(objet.display_name, PaletteUi.ACCENT))
	_contenu.add_child(_label("Quantité : %d" % GameState.quantite_objet(objet.id), PaletteUi.TEXTE))
	if objet.description != "":
		_contenu.add_child(_label(objet.description, PaletteUi.TEXTE_DOUX, true))
	_contenu.add_child(_label("Utilisable en combat" if objet.utilisable_en_combat else "Hors combat seulement",
		PaletteUi.TEXTE_DOUX))
