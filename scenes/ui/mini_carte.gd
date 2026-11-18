class_name MiniCarte
extends Control
## La mini-carte, toujours visible en haut a droite de la carte : un morceau du
## quartier centre sur le joueur, a une case par pixel. Les bandes (Zones.ORDRE)
## sont recollees : on voit la bande voisine avant d'y entrer. Le joueur clignote,
## les personnages sont des points, les reperes (soins, boutique...) gardent leur
## couleur de la grande carte.
## world.gd l'alimente avec suivre() a chaque image.

## Taille de la fenetre, en cases (= pixels a l'ecran de base).
const CASES := Vector2i(48, 30)
const MARGE := 4.0
const PERIODE_CLIGNOTEMENT := 0.4

var _zone: StringName = &""
var _joueur: Vector2i = Vector2i.ZERO
var _pnjs: Array[Vector2i] = []
var _temps: float = 0.0
## Plans recolles du nord au sud, et la ligne ou commence chaque bande.
var _lignes: Array = []
var _debut_bande: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recoller()

func _recoller() -> void:
	_lignes.clear()
	_debut_bande.clear()
	for id: StringName in Zones.ORDRE:
		_debut_bande[id] = _lignes.size()
		_lignes.append_array(Zones.zone(id)["plan"])

## Ou est le joueur, et les personnages de sa zone (cases de cette zone).
func suivre(zone: StringName, joueur: Vector2i, pnjs: Array[Vector2i]) -> void:
	_zone = zone
	_joueur = joueur
	_pnjs = pnjs
	queue_redraw()

func _process(delta: float) -> void:
	_temps += delta

func _draw() -> void:
	var ecran := get_viewport_rect().size
	var cadre := Rect2(Vector2(ecran.x - CASES.x - MARGE, MARGE), Vector2(CASES))
	draw_rect(cadre.grow(1.0), PaletteUi.BORDURE)
	draw_rect(cadre, PaletteUi.FOND)
	if not _debut_bande.has(_zone):
		return
	var decalage: int = _debut_bande[_zone]
	var centre := Vector2i(_joueur.x, _joueur.y + decalage)
	var coin := centre - CASES / 2
	var reperes: Array = []
	for dy in CASES.y:
		var y := coin.y + dy
		if y < 0 or y >= _lignes.size():
			continue
		var ligne: String = _lignes[y]
		for dx in CASES.x:
			var x := coin.x + dx
			if x < 0 or x >= ligne.length():
				continue
			var c := ligne[x]
			var p := cadre.position + Vector2(dx, dy)
			draw_rect(Rect2(p, Vector2.ONE), PaletteUi.COULEURS_CARTE.get(c, PaletteUi.CARTE_DEFAUT))
			if PaletteUi.REPERES_CARTE.has(c):
				reperes.append([p + Vector2(0.5, 0.5), c])
	for r in reperes:
		draw_circle(r[0], 1.5, PaletteUi.REPERES_CARTE[r[1]])
	for pnj in _pnjs:
		var p := cadre.position + Vector2(pnj.x - coin.x, pnj.y + decalage - coin.y) + Vector2(0.5, 0.5)
		if cadre.has_point(p):
			draw_circle(p, 1.0, PaletteUi.TEXTE)
	if fmod(_temps, PERIODE_CLIGNOTEMENT * 2.0) < PERIODE_CLIGNOTEMENT * 1.4:
		var p := cadre.position + Vector2(CASES / 2) + Vector2(0.5, 0.5)
		draw_circle(p, 2.0, PaletteUi.FOND)
		draw_circle(p, 1.5, PaletteUi.CARTE_JOUEUR)
