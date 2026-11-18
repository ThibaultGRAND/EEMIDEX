extends MiniJeu
## Mini-jeu « Rythme » : entraine la VITESSE.
## Des fleches descendent dans 4 pistes ; on appuie sur la bonne fleche quand
## elles passent sur la ligne doree. La difficulte (1 a 5, selon le niveau de
## l'alternant) regle la vitesse de chute, l'ecart entre les notes, leur nombre
## et la tolerance.

const STAT := &"vitesse"
const ACTIONS := ["ui_left", "ui_down", "ui_up", "ui_right"]
const NOMS_TOUCHES := ["←", "↓", "↑", "→"]
## Orientation de la fleche dessinee dans chaque piste (gauche, bas, haut, droite).
const DIRECTIONS := [Vector2.LEFT, Vector2.DOWN, Vector2.UP, Vector2.RIGHT]
## Proportions de l'ecran.
const PISTES_CENTRE_X := 0.6
const PISTE_ECART := 0.12
const PISTE_LARGEUR := 0.09
const LIGNE_Y := 0.78
const HAUT_Y := 0.12
const DUREE_ECLAIR := 0.15
const COMBO_FRAPPE := 5         # l'alternant frappe tous les 5 coups reussis d'affilee

var _notes: Array = []          # [{"colonne": int, "temps": float, "jouee": bool}]
var _temps: float = 0.0
var _duree: float = 0.0
var _reussites: int = 0
var _parfaits: int = 0
var _total: int = 0
var _combo: int = 0
var _eclairs: Array = [0.0, 0.0, 0.0, 0.0]
var _duree_chute: float = 1.6
var _tolerance: float = 0.18

func _consignes() -> Array:
	return ["Rythme", "la vitesse",
		"Des flèches descendent dans les 4 colonnes. Appuie sur la même flèche "
		+ "au moment où elle passe sur la ligne dorée. Plus tu en réussis, plus "
		+ gone.nom() + " gagne en vitesse."]

func _touches() -> Array:
	return [[NOMS_TOUCHES, "frapper la note de la colonne"]]

func _commencer() -> void:
	_duree_chute = 1.9 - 0.2 * difficulte            # 1,7 s au niveau 1, 0,9 s au niveau 5
	_tolerance = 0.21 - 0.02 * difficulte
	var intervalle := 0.9 - 0.1 * difficulte
	var nombre := 12 + 3 * difficulte
	_notes.clear()
	var t := _duree_chute + 0.4
	for i in nombre:
		_notes.append({"colonne": randi() % ACTIONS.size(), "temps": t, "jouee": false})
		t += intervalle * randf_range(0.8, 1.25)
	_total = nombre
	_duree = t + 0.6
	_titre.text = "Rythme — %s  (difficulté %d/%d)" % [gone.nom(), difficulte, GameState.DIFFICULTE_MINIJEU_MAX]
	_rafraichir()

func _rafraichir() -> void:
	_info.text = "Réussies %d/%d     Combo %d" % [_reussites, _total, _combo]

func _jeu_process(delta: float) -> void:
	_temps += delta
	for i in _eclairs.size():
		_eclairs[i] = maxf(0.0, float(_eclairs[i]) - delta)
	for note: Dictionary in _notes:
		if not note["jouee"] and _temps > float(note["temps"]) + _tolerance:
			note["jouee"] = true
			_combo = 0
			message("Raté", PaletteUi.JAUGE_BASSE, Vector2(_colonne_x(int(note["colonne"])), _ligne_y() - 8))
			_rafraichir()
	if _temps >= _duree:
		terminer()

func _jeu_input(event: InputEvent) -> void:
	for colonne in ACTIONS.size():
		if event.is_action_pressed(ACTIONS[colonne]):
			_frapper(colonne)
			return

func _frapper(colonne: int) -> void:
	_eclairs[colonne] = DUREE_ECLAIR
	var meilleure: Dictionary = {}
	var meilleur_ecart := 999.0
	for note: Dictionary in _notes:
		if note["jouee"] or int(note["colonne"]) != colonne:
			continue
		var ecart: float = absf(float(note["temps"]) - _temps)
		if ecart < meilleur_ecart:
			meilleur_ecart = ecart
			meilleure = note
	var x := _colonne_x(colonne)
	if meilleure.is_empty() or meilleur_ecart > _tolerance:
		message("Trop tôt", PaletteUi.TEXTE_ETEINT, Vector2(x, _ligne_y() - 8))
		return
	meilleure["jouee"] = true
	_reussites += 1
	_combo += 1
	if meilleur_ecart <= _tolerance * 0.4:
		_parfaits += 1
		message("Parfait !", PaletteUi.ACCENT, Vector2(x, _ligne_y() - 8))
	else:
		message("Bien", PaletteUi.JAUGE_HAUTE, Vector2(x, _ligne_y() - 8))
	if _combo % COMBO_FRAPPE == 0:
		jouer_perso(&"combat_pied" if (_combo / COMBO_FRAPPE) % 2 == 0 else &"combat_poing")
	GameState.jouer_son(&"clic")
	_rafraichir()

## Gain : regle de docs/regles.md (90 % : 2 + difficulte, 60 % : 1 + difficulte / 2,
## 35 % : 1), plafonne a 5 par partie.
func _calculer_gain() -> Array:
	var ratio := float(_reussites) / float(maxi(1, _total))
	var gain := 0
	if ratio >= 0.9:
		gain = 2 + difficulte
	elif ratio >= 0.6:
		gain = 1 + difficulte / 2
	elif ratio >= 0.35:
		gain = 1
	return [STAT, mini(gain, 5), "%d%% de notes réussies (%d parfaites sur %d)." % [
		int(ratio * 100.0), _parfaits, _total]]

# =============================================================================
# Dessin
# =============================================================================
func _ligne_y() -> float:
	return get_viewport_rect().size.y * LIGNE_Y

func _colonne_x(colonne: int) -> float:
	var ecran := get_viewport_rect().size
	var ecart := ecran.x * PISTE_ECART
	return ecran.x * PISTES_CENTRE_X - ecart * (ACTIONS.size() - 1) * 0.5 + ecart * colonne

func _jeu_draw() -> void:
	var ecran := get_viewport_rect().size
	var largeur := ecran.x * PISTE_LARGEUR
	var haut := ecran.y * HAUT_Y
	var ligne := _ligne_y()
	for i in ACTIONS.size():
		var x := _colonne_x(i)
		var couleur: Color = PaletteUi.MINIJEU_PISTES[i]
		draw_rect(Rect2(x - largeur * 0.5, haut, largeur, ligne - haut + largeur * 0.6), PaletteUi.MINIJEU_PISTE)
		if float(_eclairs[i]) > 0.0:
			var eclat := couleur
			eclat.a = float(_eclairs[i]) / DUREE_ECLAIR * 0.5
			draw_rect(Rect2(x - largeur * 0.5, haut, largeur, ligne - haut), eclat)
		# la touche, posee sur la ligne : cadre et fleche
		var cible := Rect2(x - largeur * 0.45, ligne - largeur * 0.45, largeur * 0.9, largeur * 0.9)
		draw_rect(cible, PaletteUi.PANNEAU)
		draw_rect(cible, couleur, false, 1.0)
		_fleche(Vector2(x, ligne), largeur * 0.28, DIRECTIONS[i], couleur.darkened(0.2))
	draw_rect(Rect2(_colonne_x(0) - largeur * 0.6, ligne - 0.5, ecran.x * PISTE_ECART * 3 + largeur * 1.2, 1.0),
		PaletteUi.ACCENT)
	# progression du morceau
	if etape == Etape.JEU and _duree > 0.0:
		var barre := Rect2(_colonne_x(0) - largeur * 0.5, haut - 5, ecran.x * PISTE_ECART * 3 + largeur, 2)
		draw_rect(barre, PaletteUi.PANNEAU)
		draw_rect(Rect2(barre.position, Vector2(barre.size.x * clampf(_temps / _duree, 0, 1), barre.size.y)),
			PaletteUi.TEXTE_DOUX)
	if etape != Etape.JEU:
		return
	for note: Dictionary in _notes:
		if note["jouee"]:
			continue
		var reste: float = float(note["temps"]) - _temps
		if reste > _duree_chute or reste < -0.25:
			continue
		var y: float = ligne - reste / _duree_chute * (ligne - haut)
		var c: int = note["colonne"]
		_fleche(Vector2(_colonne_x(c), y), largeur * 0.36, DIRECTIONS[c], PaletteUi.MINIJEU_PISTES[c])

## Une fleche pleine, pointe vers `vers`, avec un contour sombre.
func _fleche(centre: Vector2, taille: float, vers: Vector2, couleur: Color) -> void:
	var cote := Vector2(-vers.y, vers.x)
	var points := PackedVector2Array([
		centre + vers * taille,
		centre + cote * taille,
		centre + cote * taille * 0.45,
		centre + cote * taille * 0.45 - vers * taille,
		centre - cote * taille * 0.45 - vers * taille,
		centre - cote * taille * 0.45,
		centre - cote * taille,
	])
	draw_colored_polygon(points, couleur)
	points.append(points[0])
	draw_polyline(points, PaletteUi.FOND, 1.0)
