extends Control
## Le décor de l'écran de combat, dessiné en code : aube sur la Confluence,
## la Saône et le Rhône qui se rejoignent, Fourvière et le Monolithe en
## silhouette, et deux plateformes de quai sous les combattants.
##
## Rien n'est un asset : tout est tracé dans _draw(), comme les cadres de
## l'interface sont des StyleBoxFlat. Les couleurs du décor vivent ici et
## nulle part ailleurs ; PaletteUi ne porte que les couleurs de l'interface.
##
## Il est dessiné dans un espace de 320x180 et se remet à l'échelle si la
## résolution change.

const LARGEUR_REF := 320.0
const HAUTEUR_REF := 180.0

## Hauteurs de référence, en pixels, dans l'espace 320x180.
const HORIZON := 58
const EAU_BAS := 76
const QUAI_LOIN := 96

const CIEL_HAUT := Color("1b2440")
const CIEL_BAS := Color("8a5a6d")
const LUEUR := Color("e0915c")
const SILHOUETTE := Color("111726")
const SILHOUETTE_CLAIRE := Color("1b2335")
const EAU := Color("27405a")
const EAU_REFLET := Color("3c6382")
const EAU_SOLEIL := Color("b4764f")
const QUAI_LOINTAIN := Color("46513f")
const QUAI_PROCHE := Color("57634a")
const QUAI_BORD := Color("6d7b5c")
const PLATEFORME := Color("3d4738")
const PLATEFORME_BORD := Color("77855f")

## Les bâtiments de la rive, en (x, largeur, hauteur au-dessus de l'horizon).
## Dessinés à la main : la fiche du joueur couvre le haut à gauche, les toits
## restent donc bas de ce côté, et la colline est posée à droite du centre.
const BATIMENTS := [
	Vector3i(2, 16, 10), Vector3i(20, 10, 13), Vector3i(32, 20, 7),
	Vector3i(54, 12, 11), Vector3i(68, 22, 6), Vector3i(92, 14, 9),
	Vector3i(252, 18, 8), Vector3i(272, 12, 12), Vector3i(286, 22, 6),
	Vector3i(308, 12, 10),
]

## Fourvière : la colline arrondie, la basilique et ses deux tours. Son sommet
## tombe entre la fiche du joueur et le sprite de l'adversaire, sinon on ne
## verrait que ses flancs.
const COLLINE_X := 150
const COLLINE_LARGEUR := 80
const COLLINE_HAUTEUR := 30
## Le Monolithe de Confluence, là où se trouve l'EEMI.
const MONOLITHE := Vector3i(138, 11, 26)
## Le soleil qui se lève, et son reflet dans l'eau.
const SOLEIL := Vector2(112, 51)
const SOLEIL_RAYON := 5.0

## Centres des deux plateformes, dans l'espace 320x180.
const PLATEFORME_ENNEMI := Vector2(240, 60)
const PLATEFORME_JOUEUR := Vector2(74, 104)
const PLATEFORME_RAYON := Vector2(34, 7)

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var e := Vector2(size.x / LARGEUR_REF, size.y / HAUTEUR_REF)
	_dessiner_ciel(e)
	_dessiner_silhouettes(e)
	_dessiner_eau(e)
	_dessiner_quais(e)
	_dessiner_plateforme(PLATEFORME_ENNEMI, e)
	_dessiner_plateforme(PLATEFORME_JOUEUR, e)

## Dégradé d'aube, ligne par ligne, plus une lueur juste au-dessus de l'eau.
func _dessiner_ciel(e: Vector2) -> void:
	for y in HORIZON:
		var t := float(y) / float(HORIZON - 1)
		# Courbe : le ciel reste sombre longtemps et s'embrase près de l'horizon.
		var couleur := CIEL_HAUT.lerp(CIEL_BAS, t * t)
		if y > HORIZON - 10:
			couleur = couleur.lerp(LUEUR, float(y - (HORIZON - 10)) / 14.0)
		_ligne(0, y, LARGEUR_REF, 1, couleur, e)
	draw_colored_polygon(
		_ellipse(SOLEIL, Vector2(SOLEIL_RAYON, SOLEIL_RAYON), e), LUEUR)

func _dessiner_silhouettes(e: Vector2) -> void:
	# La colline, colonne par colonne : un dôme, pas un escalier.
	var sommet := 0
	for i in COLLINE_LARGEUR:
		var t := float(i) / float(COLLINE_LARGEUR - 1)
		var hauteur := int(round(COLLINE_HAUTEUR * pow(sin(PI * t), 0.7)))
		sommet = maxi(sommet, hauteur)
		if hauteur > 0:
			_ligne(COLLINE_X + i, HORIZON - hauteur, 1, hauteur,
				SILHOUETTE_CLAIRE, e)
	# La basilique au sommet : un corps et deux tours.
	var bx := COLLINE_X + COLLINE_LARGEUR / 2 - 7
	_ligne(bx, HORIZON - sommet - 6, 14, 6, SILHOUETTE, e)
	_ligne(bx + 1, HORIZON - sommet - 11, 3, 5, SILHOUETTE, e)
	_ligne(bx + 10, HORIZON - sommet - 11, 3, 5, SILHOUETTE, e)
	for b: Vector3i in BATIMENTS:
		_ligne(b.x, HORIZON - b.z, b.y, b.z, SILHOUETTE, e)
	_ligne(MONOLITHE.x, HORIZON - MONOLITHE.z, MONOLITHE.y, MONOLITHE.z,
		SILHOUETTE, e)

## La confluence : deux eaux qui se rejoignent, et le soleil dessus.
## Rides de l'eau : des traits courts, posés à la main pour qu'aucun ne
## traverse l'écran ni ne coupe une plateforme.
const RIDES := [
	Vector3i(14, 2, 18), Vector3i(48, 5, 11), Vector3i(86, 3, 22),
	Vector3i(120, 8, 14), Vector3i(196, 4, 16), Vector3i(228, 9, 12),
	Vector3i(262, 6, 20), Vector3i(296, 11, 15),
]

func _dessiner_eau(e: Vector2) -> void:
	_ligne(0, HORIZON, LARGEUR_REF, EAU_BAS - HORIZON, EAU, e)
	for ride: Vector3i in RIDES:
		_ligne(ride.x, HORIZON + 1 + ride.y, ride.z, 1, EAU_REFLET, e)
	# Le reflet du soleil, juste sous lui : des traits qui s'écartent.
	for i in 5:
		var largeur := 14 - i * 2
		_ligne(SOLEIL.x - largeur / 2.0, HORIZON + 1 + i * 3, largeur, 1,
			EAU_SOLEIL, e)

func _dessiner_quais(e: Vector2) -> void:
	_ligne(0, EAU_BAS, LARGEUR_REF, 1, QUAI_BORD, e)
	_ligne(0, EAU_BAS + 1, LARGEUR_REF, QUAI_LOIN - EAU_BAS, QUAI_LOINTAIN, e)
	_ligne(0, QUAI_LOIN, LARGEUR_REF, HAUTEUR_REF - QUAI_LOIN, QUAI_PROCHE, e)

## Le disque de quai sous un combattant : une ellipse aplatie, cerclée.
func _dessiner_plateforme(centre: Vector2, e: Vector2) -> void:
	draw_colored_polygon(_ellipse(centre, PLATEFORME_RAYON, e), PLATEFORME)
	draw_colored_polygon(
		_ellipse(centre + Vector2(0, -1), PLATEFORME_RAYON - Vector2(2, 1), e),
		PLATEFORME_BORD)
	draw_colored_polygon(
		_ellipse(centre + Vector2(0, -1), PLATEFORME_RAYON - Vector2(4, 2), e),
		PLATEFORME)

func _ellipse(centre: Vector2, rayon: Vector2, e: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 24:
		var angle := TAU * float(i) / 24.0
		points.append((centre + Vector2(cos(angle), sin(angle)) * rayon) * e)
	return points

## Un rectangle posé dans l'espace 320x180, remis à l'échelle de l'écran.
func _ligne(x: float, y: float, largeur: float, hauteur: float,
		couleur: Color, e: Vector2) -> void:
	draw_rect(Rect2(Vector2(x, y) * e, Vector2(largeur, hauteur) * e), couleur)
