class_name CarteMonde
extends Control
## La carte du monde : les zones de la Confluence empilées du nord au sud,
## les lieux importants et l'endroit où se trouve le joueur.
## Ouverte par la carte (world.gd) avec ouvrir() ; se ferme toute seule et
## prévient par le signal fermee.

signal fermee

## Ordre des zones, du nord au sud (une zone mène à la suivante).
const ORDRE: Array[StringName] = [&"perrache", &"sainte_blandine", &"darse", &"pointe"]
## Écart entre deux zones, en cases (le chemin entre zones passe dedans).
const ECART := 5
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
	var haut := MARGE * 2 + TAILLE_TEXTE + 4      # place pour le titre de la carte
	hauteur_cases += ECART * 2
	var dispo := Vector2(size.x - LARGEUR_LEGENDE - MARGE * 3, size.y - haut - MARGE - TAILLE_TEXTE - 4)
	var largeur_cases := Zones.LARGEUR * COLONNES + ECART * (COLONNES - 1)
	var cote: float = minf(dispo.y / hauteur_cases, dispo.x / largeur_cases)
	var origine := Vector2(MARGE, haut + ECART * cote)

	var noms: Array = []
	var coins := {}
	for i in ORDRE.size():
		var id: StringName = ORDRE[i]
		var colonne := i / par_colonne
		var y_zone := 0
		for precedente in ORDRE.slice(colonne * par_colonne, i):
			y_zone += Zones.zone(precedente)["plan"].size() + ECART
		var plan: Array = Zones.zone(id)["plan"]
		var coin := origine + Vector2(colonne * (Zones.LARGEUR + ECART), y_zone) * cote
		coins[id] = coin
		_dessiner_zone(plan, coin, cote)
		var cadre := Rect2(coin, Vector2(Zones.LARGEUR, plan.size()) * cote)
		var courante: bool = id == _zone_courante
		draw_rect(cadre, PaletteUi.ACCENT if courante else PaletteUi.BORDURE, false, 1.0)
		noms.append([id, cadre, courante])
		var court: String = str(Zones.zone(id)["titre"]).split(" — ")[0]
		# Le nom se place à droite du chemin qui entre par le haut de la zone.
		var x_nom := 0.0
		if i > 0:
			x_nom = (_centre_sortie(id, ORDRE[i - 1]).x + 1.5) * cote
		# Taille réduite si le nom déborde du cadre.
		var taille_nom := TAILLE_TEXTE - 2
		while taille_nom > 4 and police.get_string_size(court, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_nom).x > cadre.size.x - x_nom:
			taille_nom -= 1
		draw_string(police, cadre.position + Vector2(x_nom, -2), court, HORIZONTAL_ALIGNMENT_LEFT, -1, taille_nom,
			PaletteUi.ACCENT if courante else PaletteUi.TEXTE)
		if courante and _joueur_visible:
			var centre := coin + (Vector2(_case_joueur) + Vector2(0.5, 0.5)) * cote
			draw_circle(centre, maxf(cote * 1.4, 2.5), PaletteUi.FOND)
			draw_circle(centre, maxf(cote * 1.0, 2.0), PaletteUi.CARTE_JOUEUR)

	# Les chemins d'une zone à la suivante, de la sortie de l'une à l'entrée de l'autre.
	for i in ORDRE.size() - 1:
		_dessiner_chemin(ORDRE[i], ORDRE[i + 1], coins, cote)

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
	draw_line(Vector2(x_legende, y - 3), Vector2(x_legende + 6, y - 3), PaletteUi.CARTE_CHEMIN, 1.5)
	draw_string(police, Vector2(x_legende + 10, y), "Chemin entre zones", HORIZONTAL_ALIGNMENT_LEFT, -1, TAILLE_TEXTE, PaletteUi.TEXTE_DOUX)
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

## Centre des cases de sortie de la zone id qui mènent à la zone vers (en cases).
func _centre_sortie(id: StringName, vers: StringName) -> Vector2:
	var sorties: Dictionary = Zones.zone(id)["sorties"]
	var plan: Array = Zones.zone(id)["plan"]
	var total := Vector2.ZERO
	var nombre := 0
	for c: String in sorties:
		if sorties[c][0] != vers:
			continue
		for y in plan.size():
			var ligne: String = plan[y]
			for x in ligne.length():
				if ligne[x] == c:
					total += Vector2(x, y) + Vector2(0.5, 0.5)
					nombre += 1
	return total / maxi(nombre, 1)

## Trace le chemin de la sortie du bas de depuis jusqu'à l'entrée du haut de vers.
## Dans la même colonne, un simple trait ; sinon le chemin descend, passe entre les
## deux colonnes et redescend dans la zone suivante, au-dessus de son nom.
func _dessiner_chemin(depuis: StringName, vers: StringName, coins: Dictionary, cote: float) -> void:
	var a: Vector2 = coins[depuis] + _centre_sortie(depuis, vers) * cote
	var b: Vector2 = coins[vers] + _centre_sortie(vers, depuis) * cote
	var points := PackedVector2Array([a])
	if absf(a.x - b.x) > cote:
		var bas := a.y + (ECART * 0.5 + 0.5) * cote
		var haut := b.y - (ECART - 0.5) * cote
		# Le couloir entre les deux colonnes, du côté de la zone suivante.
		var couloir: float = coins[depuis].x + (Zones.LARGEUR + ECART * 0.5) * cote
		if a.x > b.x:
			couloir = coins[depuis].x - ECART * 0.5 * cote
		points.append_array([Vector2(a.x, bas), Vector2(couloir, bas), Vector2(couloir, haut), Vector2(b.x, haut)])
	points.append(b)
	var epaisseur := maxf(cote * 0.6, 1.5)
	draw_polyline(points, PaletteUi.FOND, epaisseur + 2.0)
	draw_polyline(points, PaletteUi.CARTE_CHEMIN, epaisseur)
	# Pointe de flèche à l'arrivée, vers le bas.
	var p := maxf(cote * 1.2, 3.0)
	draw_colored_polygon(PackedVector2Array([b, b + Vector2(-p, -p), b + Vector2(p, -p)]), PaletteUi.CARTE_CHEMIN)
