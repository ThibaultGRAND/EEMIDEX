extends MiniJeu
## Mini-jeu « Frappe chronometree » : entraine l'ATTAQUE.
## Un curseur fait des allers-retours sur une barre ; on appuie sur Entree quand
## il est dans la zone. Au centre (dore) : 3 points, autour : 2 puis 1.
## La difficulte (1 a 5, selon le niveau de l'alternant) regle la vitesse du
## curseur et la largeur de la zone ; a partir de 4, la zone se deplace.

const STAT := &"attaque"
const COUPS := 6
## La barre, en proportions de l'ecran.
const BARRE_X := 0.3
const BARRE_LARGEUR := 0.62
const BARRE_Y := 0.62
const BARRE_HAUTEUR := 0.07
## Parts de la zone qui donnent 3 et 2 points.
const PART_PARFAIT := 0.35
const PART_TRES_BIEN := 0.7

var _curseur: float = 0.0
var _sens: float = 1.0
var _vitesse: float = 1.2
var _centre: float = 0.5
var _sens_zone: float = 1.0
var _vitesse_zone: float = 0.0
var _demi_largeur: float = 0.14
var _coups_restants: int = COUPS
var _score: int = 0
var _balancement: float = 0.0       # le sac de frappe qui bouge apres un coup

func _consignes() -> Array:
	return ["Frappe chronométrée", "l'attaque",
		"Un curseur blanc fait des allers-retours sur la barre. Appuie sur Entrée "
		+ "quand il passe dans la zone verte : au centre doré, c'est 3 points. "
		+ "%d coups pour marquer le plus possible." % COUPS]

func _touches() -> Array:
	return [[["Entrée"], "frapper"]]

## L'alternant a gauche, face au sac de frappe.
func _position_perso() -> Vector2:
	var ecran := get_viewport_rect().size
	return Vector2(ecran.x * 0.12, ecran.y * 0.72)

func _commencer() -> void:
	_vitesse = 0.7 + 0.25 * difficulte                  # 0,95 a 1,95 barre par seconde
	_demi_largeur = 0.19 - 0.025 * difficulte           # zone de plus en plus etroite
	_vitesse_zone = 0.12 * maxi(0, difficulte - 3)      # niveaux 4 et 5 : la zone bouge
	_nouvelle_cible()
	_titre.text = "Frappe chronométrée — %s  (difficulté %d/%d)" % [
		gone.nom(), difficulte, GameState.DIFFICULTE_MINIJEU_MAX]
	_rafraichir()

func _nouvelle_cible() -> void:
	_centre = randf_range(0.15 + _demi_largeur, 0.85 - _demi_largeur)
	_sens_zone = 1.0 if randf() < 0.5 else -1.0

func _rafraichir() -> void:
	_info.text = "Score %d     Coups restants %d" % [_score, _coups_restants]

func _jeu_process(delta: float) -> void:
	_curseur += _sens * _vitesse * delta
	if _curseur >= 1.0:
		_curseur = 1.0
		_sens = -1.0
	elif _curseur <= 0.0:
		_curseur = 0.0
		_sens = 1.0
	if _vitesse_zone > 0.0:
		_centre += _sens_zone * _vitesse_zone * delta
		if _centre > 1.0 - _demi_largeur or _centre < _demi_largeur:
			_sens_zone = -_sens_zone
			_centre = clampf(_centre, _demi_largeur, 1.0 - _demi_largeur)
	_balancement = move_toward(_balancement, 0.0, delta * 2.0)

func _jeu_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_frapper()

func _frapper() -> void:
	var ecart := absf(_curseur - _centre)
	var points := 0
	var texte := "Raté"
	var couleur := PaletteUi.JAUGE_BASSE
	if ecart <= _demi_largeur * PART_PARFAIT:
		points = 3
		texte = "Parfait ! +3"
		couleur = PaletteUi.MINIJEU_ZONE_PARFAIT
	elif ecart <= _demi_largeur * PART_TRES_BIEN:
		points = 2
		texte = "Très bien +2"
		couleur = PaletteUi.MINIJEU_ZONE_TRES_BIEN
	elif ecart <= _demi_largeur:
		points = 1
		texte = "Bien +1"
		couleur = PaletteUi.MINIJEU_ZONE_TRES_BIEN
	var barre := _barre()
	message(texte, couleur, Vector2(barre.position.x + _curseur * barre.size.x, barre.position.y - 6))
	if points > 0:
		GameState.jouer_son(&"attaque")
		jouer_perso(&"combat_pied" if points == 3 else &"combat_poing")
		_balancement = float(points) / 3.0
	else:
		jouer_perso(&"combat_touche")
	_score += points
	_coups_restants -= 1
	_nouvelle_cible()
	_rafraichir()
	if _coups_restants <= 0:
		terminer()

## Gain : regle de docs/regles.md, score x difficulte / 4, plafonne a 3. Le score
## est ramene sur 9 (l'echelle de l'ancienne partie a 3 coups) : jouer plus
## longtemps ne rapporte pas plus, il faut juste viser juste plus souvent.
func _calculer_gain() -> Array:
	var sur_neuf := float(_score) * 9.0 / float(COUPS * 3)
	var gain := clampi(int(floor(sur_neuf * float(difficulte) / 4.0)), 0, 3)
	return [STAT, gain, "Score : %d / %d" % [_score, COUPS * 3]]

# =============================================================================
# Dessin
# =============================================================================
func _barre() -> Rect2:
	var ecran := get_viewport_rect().size
	return Rect2(ecran.x * BARRE_X, ecran.y * BARRE_Y, ecran.x * BARRE_LARGEUR, ecran.y * BARRE_HAUTEUR)

func _jeu_draw() -> void:
	var ecran := get_viewport_rect().size
	_dessiner_sac(Vector2(ecran.x * 0.24, ecran.y * 0.4))
	var barre := _barre()
	draw_rect(barre, PaletteUi.MINIJEU_PISTE)
	if etape == Etape.JEU or etape == Etape.DECOMPTE:
		var debut := barre.position.x + (_centre - _demi_largeur) * barre.size.x
		var largeur := 2.0 * _demi_largeur * barre.size.x
		draw_rect(Rect2(debut, barre.position.y, largeur, barre.size.y), PaletteUi.MINIJEU_ZONE_BIEN)
		var tres_bien := largeur * PART_TRES_BIEN
		draw_rect(Rect2(debut + (largeur - tres_bien) * 0.5, barre.position.y, tres_bien, barre.size.y),
			PaletteUi.MINIJEU_ZONE_TRES_BIEN)
		var parfait := largeur * PART_PARFAIT
		draw_rect(Rect2(debut + (largeur - parfait) * 0.5, barre.position.y, parfait, barre.size.y),
			PaletteUi.MINIJEU_ZONE_PARFAIT)
		# le curseur : un trait et une pointe au-dessus
		var x := barre.position.x + _curseur * barre.size.x
		draw_rect(Rect2(x - 1.0, barre.position.y - 3, 2.0, barre.size.y + 6), PaletteUi.MINIJEU_CURSEUR)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 4, barre.position.y - 8), Vector2(x + 4, barre.position.y - 8),
			Vector2(x, barre.position.y - 3)]), PaletteUi.MINIJEU_CURSEUR)
	draw_rect(barre, PaletteUi.BORDURE, false, 1.0)
	# legende sous la barre
	var y := barre.end.y + 10
	var x0 := barre.position.x
	for entree: Array in [[PaletteUi.MINIJEU_ZONE_PARFAIT, "Parfait 3"],
			[PaletteUi.MINIJEU_ZONE_TRES_BIEN, "Très bien 2"], [PaletteUi.MINIJEU_ZONE_BIEN, "Bien 1"]]:
		draw_rect(Rect2(x0, y - 5, 5, 5), entree[0])
		_ecrire(str(entree[1]), Vector2(x0 + 7, y), PaletteUi.TEXTE_DOUX, 8)
		x0 += barre.size.x / 3.0
	# coups restants : une pastille par coup
	for i in COUPS:
		var centre := Vector2(barre.end.x - 4 - (COUPS - 1 - i) * 10, barre.position.y - 14)
		draw_circle(centre, 3.0, PaletteUi.ACCENT if i < _coups_restants else PaletteUi.TEXTE_ETEINT)

## Le sac de frappe, suspendu, qui se balance apres un coup.
func _dessiner_sac(attache: Vector2) -> void:
	var angle := sin(Time.get_ticks_msec() / 90.0) * 0.25 * _balancement
	var bas := attache + Vector2(sin(angle), cos(angle)) * 14.0
	draw_line(attache, bas, PaletteUi.MINIJEU_CORDE, 1.0)
	var sac := Rect2(bas.x - 7, bas.y, 14, 34)
	draw_rect(sac, PaletteUi.MINIJEU_SAC)
	draw_rect(Rect2(sac.position.x, sac.position.y + 6, sac.size.x, 2), PaletteUi.MINIJEU_SAC.darkened(0.3))
	draw_rect(Rect2(sac.position.x, sac.end.y - 8, sac.size.x, 2), PaletteUi.MINIJEU_SAC.darkened(0.3))
	draw_rect(sac, PaletteUi.FOND, false, 1.0)
