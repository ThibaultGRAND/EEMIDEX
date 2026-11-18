class_name CarteMonde
extends Control
## La carte du monde : les zones de la Confluence empilées du nord au sud,
## les lieux importants et l'endroit où se trouve le joueur.
## Ouverte par la carte (world.gd) avec ouvrir() ; se ferme toute seule et
## prévient par le signal fermee.

signal fermee

## Ordre des zones, du nord au sud (une zone mène à la suivante).
const ORDRE: Array[StringName] = [&"perrache", &"sainte_blandine", &"darse", &"pointe"]
## Écart entre deux zones, en cases.
const ECART := 3
## Nombre de colonnes de zones (plus de colonnes = carte plus grande).
const COLONNES := 2
const TAILLE_TEXTE := 8
const MARGE := 8.0
const LARGEUR_LEGENDE := 110.0
const PERIODE_CLIGNOTEMENT := 0.4

const LEGENDE := [
	["S", "Soins"], ["B", "Boutique"], ["M", "Entraînement"], ["T", "Passage sous les voies"],
	["R", "Ressource"], ["X", "Combat final"], ["1", "Sortie"],
]

var _zone_courante: StringName = &""
var _case_joueur: Vector2i = Vector2i.ZERO
var _joueur_visible: bool = true
var _temps: float = 0.0

func _ready() -> void:
	visible = false
	set_process(false)

func ouvrir(zone: StringName, case_joueur: Vector2i) -> void:
	_zone_courante = zone
	_case_joueur = case_joueur
	_joueur_visible = true
	_temps = 0.0
	visible = true
	set_process(true)
	queue_redraw()

func fermer() -> void:
	visible = false
	set_process(false)
	fermee.emit()

func _process(delta: float) -> void:
	_temps += delta
	if _temps >= PERIODE_CLIGNOTEMENT:
		_temps = 0.0
		_joueur_visible = not _joueur_visible
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		fermer()
	elif event is InputEventKey or event is InputEventJoypadButton:
		get_viewport().set_input_as_handled()      # la carte garde la main

func _draw() -> void:
	var police := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), PaletteUi.FOND)
	draw_string(police, Vector2(MARGE, MARGE + TAILLE_TEXTE), "Carte de la Confluence",
		HORIZONTAL_ALIGNMENT_LEFT, -1, TAILLE_TEXTE, PaletteUi.ACCENT)

	# Les zones en COLONNES colonnes, lues de haut en bas puis de gauche à droite
	# (le nord en haut à gauche, le sud en bas à droite).
	var par_colonne := ceili(ORDRE.size() / float(COLONNES))
	var hauteur_cases := 0
	for k in COLONNES:
		var h := 0
		for id in ORDRE.slice(k * par_colonne, (k + 1) * par_colonne):
			h += Zones.zone(id)["plan"].size() + ECART
		hauteur_cases = maxi(hauteur_cases, h - ECART)
	var haut := MARGE * 2 + TAILLE_TEXTE + 4      # place pour le nom de la zone au-dessus du cadre
	var dispo := Vector2(size.x - LARGEUR_LEGENDE - MARGE * 3, size.y - haut - MARGE - TAILLE_TEXTE - 4)
	var largeur_cases := Zones.LARGEUR * COLONNES + ECART * (COLONNES - 1)
	var cote: float = minf(dispo.y / hauteur_cases, dispo.x / largeur_cases)
	var origine := Vector2(MARGE, haut)

	var noms: Array = []
	for i in ORDRE.size():
		var id: StringName = ORDRE[i]
		var colonne := i / par_colonne
		var y_zone := 0
		for precedente in ORDRE.slice(colonne * par_colonne, i):
			y_zone += Zones.zone(precedente)["plan"].size() + ECART
		var plan: Array = Zones.zone(id)["plan"]
		var coin := origine + Vector2(colonne * (Zones.LARGEUR + ECART), y_zone) * cote
		_dessiner_zone(plan, coin, cote)
		var cadre := Rect2(coin, Vector2(Zones.LARGEUR, plan.size()) * cote)
		var courante: bool = id == _zone_courante
		draw_rect(cadre, PaletteUi.ACCENT if courante else PaletteUi.BORDURE, false, 1.0)
		noms.append([id, cadre, courante])
		var court: String = str(Zones.zone(id)["titre"]).split(" — ")[0]
		draw_string(police, cadre.position + Vector2(0, -2), court, HORIZONTAL_ALIGNMENT_LEFT, -1, TAILLE_TEXTE - 2,
			PaletteUi.ACCENT if courante else PaletteUi.TEXTE)
		if courante and _joueur_visible:
			var centre := coin + (Vector2(_case_joueur) + Vector2(0.5, 0.5)) * cote
			draw_circle(centre, maxf(cote * 1.4, 2.5), PaletteUi.FOND)
			draw_circle(centre, maxf(cote * 1.0, 2.0), PaletteUi.CARTE_JOUEUR)

	# Légende : les zones (la courante en accent), puis les repères.
	var x_legende := origine.x + largeur_cases * cote + MARGE * 2
	var y := haut + TAILLE_TEXTE
	for entree in noms:
		var titre: String = str(Zones.zone(entree[0])["titre"]).split(" — ")[0]
		var couleur := PaletteUi.ACCENT if entree[2] else PaletteUi.TEXTE
		var marque := "> " if entree[2] else "  "
		draw_string(police, Vector2(x_legende, y), marque + titre, HORIZONTAL_ALIGNMENT_LEFT, -1, TAILLE_TEXTE, couleur)
		y += TAILLE_TEXTE + 3
	y += 6
	draw_circle(Vector2(x_legende + 3, y - 3), 2.5, PaletteUi.CARTE_JOUEUR)
	draw_string(police, Vector2(x_legende + 10, y), "Vous êtes ici", HORIZONTAL_ALIGNMENT_LEFT, -1, TAILLE_TEXTE, PaletteUi.TEXTE)
	y += TAILLE_TEXTE + 3
	for repere in LEGENDE:
		draw_circle(Vector2(x_legende + 3, y - 3), 2.5, PaletteUi.REPERES_CARTE[repere[0]])
		draw_string(police, Vector2(x_legende + 10, y), repere[1], HORIZONTAL_ALIGNMENT_LEFT, -1, TAILLE_TEXTE, PaletteUi.TEXTE_DOUX)
		y += TAILLE_TEXTE + 3

	draw_string(police, Vector2(MARGE, size.y - MARGE), "Échap ou Entrée : fermer",
		HORIZONTAL_ALIGNMENT_LEFT, -1, TAILLE_TEXTE, PaletteUi.TEXTE_DOUX)

func _dessiner_zone(plan: Array, coin: Vector2, cote: float) -> void:
	var reperes: Array = []
	for y in plan.size():
		var ligne: String = plan[y]
		for x in ligne.length():
			var c := ligne[x]
			var case := Rect2(coin + Vector2(x, y) * cote, Vector2(cote, cote) + Vector2(0.05, 0.05))
			draw_rect(case, PaletteUi.COULEURS_CARTE.get(c, PaletteUi.CARTE_DEFAUT))
			if PaletteUi.REPERES_CARTE.has(c):
				reperes.append([coin + (Vector2(x, y) + Vector2(0.5, 0.5)) * cote, c])
	# Les repères par-dessus, plus gros qu'une case pour rester lisibles.
	for r in reperes:
		draw_circle(r[0], maxf(cote, 2.0), PaletteUi.FOND)
		draw_circle(r[0], maxf(cote * 0.75, 1.5), PaletteUi.REPERES_CARTE[r[1]])
