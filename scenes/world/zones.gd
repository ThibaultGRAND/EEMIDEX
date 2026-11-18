class_name Zones
extends RefCounted
## Les 3 zones du MVP, decrites en texte. Une ligne = une rangee de cases.
## world.gd construit les TileMapLayer a partir de ces plans.
##
## Legende :
##   #  batiment / mur (bloquant)     .  pave           ,  pave use
##   q  dalle de quai                 w  eau (bloquant) s  sable
##   h  herbe courte                  g  herbe haute (rencontres)
##   t  arbre (bloquant)              d  terre
##   S  soin      B  boutique     M  entrainement
##   T  traboule  R  ressource    X  combat de fin
##   1 2 3  sortie vers une autre zone

const LARGEUR := 32
const HAUTEUR := 20
const TAILLE_CASE := 16

## Cases que le joueur ne peut pas traverser.
const BLOQUANTS := "#wt"

## Sols simples ou les PNJ ont le droit de se balader (pas d'herbe haute,
## de traboule, de sortie ni de lieu special).
const SOLS_PNJ := ".,qhsd"

## Les deux sources du TileSet assets/tilesets/lyon.tres.
const IMPORT := 0        # les tuiles dessinees par l'equipe
const PLACEHOLDER := 1   # ce qui manque encore, en attendant

## Sol pose sur la couche du bas : caractere -> [source, case de l'atlas].
const SOLS := {
	"#": [IMPORT, Vector2i(4, 0)],      # terre, sous les batiments
	".": [IMPORT, Vector2i(0, 0)],      # pave lyonnais
	",": [IMPORT, Vector2i(1, 0)],      # pave use
	"m": [IMPORT, Vector2i(2, 0)],      # pave avec mousse
	"q": [IMPORT, Vector2i(3, 0)],      # dalle de quai
	"d": [IMPORT, Vector2i(4, 0)],      # terre et gravier
	"h": [IMPORT, Vector2i(5, 0)],      # herbe courte
	"g": [IMPORT, Vector2i(6, 0)],      # herbe haute : declenche les rencontres
	"w": [IMPORT, Vector2i(7, 0)],      # eau
	"s": [IMPORT, Vector2i(6, 1)],      # sable de berge
	"t": [IMPORT, Vector2i(5, 0)],      # herbe, sous l'arbre
	"S": [IMPORT, Vector2i(3, 0)],
	"B": [IMPORT, Vector2i(3, 0)],
	"M": [IMPORT, Vector2i(3, 0)],
	"T": [IMPORT, Vector2i(3, 0)],
	"R": [IMPORT, Vector2i(5, 0)],      # l'objet a ramasser est en decor
	"X": [IMPORT, Vector2i(3, 0)],
	"1": [IMPORT, Vector2i(0, 14)],     # marqueur de sortie grave au sol
	"2": [IMPORT, Vector2i(0, 14)],
	"3": [IMPORT, Vector2i(0, 14)],
}

## Volume pose sur la couche du haut, triee en profondeur.
const DECORS := {
	"#": [PLACEHOLDER, Vector2i(0, 2)],   # mur : planche 5 a refaire
	"t": [PLACEHOLDER, Vector2i(5, 2)],   # arbre : planche 9 jamais recue
	"S": [PLACEHOLDER, Vector2i(6, 3)],   # croix de soin
	"B": [PLACEHOLDER, Vector2i(5, 3)],   # enseigne de boutique
	"X": [PLACEHOLDER, Vector2i(7, 3)],   # le gardien de Fourviere
	"M": [IMPORT, Vector2i(7, 13)],       # borne d'entrainement
	"T": [IMPORT, Vector2i(6, 13)],       # porche de traboule
}

## Partie haute des volumes qui font deux cases, posee sur la case du dessus.
const DECORS_HAUT := {
	"#": [PLACEHOLDER, Vector2i(1, 2)],
	"t": [PLACEHOLDER, Vector2i(6, 2)],
}

const ZONES := {
	&"presquile": {
		"titre": "Presqu'île — Bellecour",
		"ressource": &"praline",
		"tuile_ressource": Vector2i(3, 13),
		"rencontres": [&"generique_gone", &"generique_quenellon"],
		"niveau_min": 3,
		"niveau_max": 5,
		"depart": Vector2i(16, 9),
		"plan": [
			"################################",
			"#ttt##########################t#",
			"#..............................#",
			"#..###...###......###...###....#",
			"#..###...###...S..###...###....#",
			"#..............................#",
			"wwqq,,,,,,,,,,,,,,,,,,,,,,,,...#",
			"wwqq,,,,,,,,,,,,,,,,,,,,,,,,...#",
			"wwqq,,,,,,,,,,,,,,,,,,,,,,,,...#",
			"2qqq,,,,,,,,,,,,,,,,,,,,,,,,...#",
			"wwqq,,,,,,,,,,,,,,,,,,,,,,,,...#",
			"wwqq,,,,,,,,,,,,,,,,,,,,,,,,...#",
			"wwqq,,,,,,,,,,,,,,,,,,,,,,,,...#",
			"#..............................#",
			"#..hhgg.......###......hhgg....#",
			"#..hhgg...M...###......hhgg....#",
			"#..hhgg................hhgg....#",
			"#.........R........B...........#",
			"#t...........................t.#",
			"################################",
		],
		"sorties": {"2": ["vieux_lyon", 30, 7]},
		## PNJ qui se baladent : sprite 2 foulees x 4 directions, case de depart.
		"pnj": [
			{"nom": "PnjSeb", "sprite": "res://assets/sprites/pnj_seb.png", "case": Vector2i(8, 5)},
			{"nom": "PnjThomas", "sprite": "res://assets/sprites/pnj_thomas.png", "case": Vector2i(22, 9)},
			{"nom": "PnjJulian", "sprite": "res://assets/sprites/pnj_julian.png", "case": Vector2i(10, 12)},
			{"nom": "PnjPaloma", "sprite": "res://assets/sprites/pnj_paloma.png", "case": Vector2i(17, 16)},
		],
	},
	&"vieux_lyon": {
		"titre": "Vieux Lyon — les traboules",
		"ressource": &"cocon",
		"tuile_ressource": Vector2i(4, 13),
		"rencontres": [&"generique_gone", &"generique_traboulin"],
		"niveau_min": 5,
		"niveau_max": 8,
		"depart": Vector2i(30, 7),
		"plan": [
			"################################",
			"#..............................#",
			"#.####.####.####.####.####.###.#",
			"#.####.####.####.####.####.###.#",
			"#..............................#",
			"#.####.#T##.####.####.#T##.###.#",
			"#.####.####.####.####.####.###.#",
			"#..............................1",
			"#..............................#",
			"3..............................#",
			"#..gg....R.........gg..........#",
			"#..gg..............gg..........#",
			"#.####.####.####.####.####.###.#",
			"#.####.####.####.####.####.###.#",
			"#..............................#",
			"#..gg.......R......gg..........#",
			"#..gg..............gg..........#",
			"#..............................#",
			"#.####.####.####.####.####.###.#",
			"################################",
		],
		"sorties": {"1": ["presquile", 1, 9], "3": ["fourviere", 1, 8]},
	},
	&"fourviere": {
		"titre": "Fourvière — la colline",
		"ressource": &"quenelle",
		"tuile_ressource": Vector2i(5, 13),
		"rencontres": [&"generique_traboulin", &"generique_quenellon"],
		"niveau_min": 8,
		"niveau_max": 11,
		"depart": Vector2i(1, 8),
		"plan": [
			"################################",
			"#tt##########tt###########tt####",
			"#..............................#",
			"#..hhh....########....hhh......#",
			"#..hhh....########....hhh......#",
			"#.........########.............#",
			"#..gg.................gg.......#",
			"#..gg......R..........gg.......#",
			"2..............................#",
			"#..............................#",
			"#...........X..................#",
			"#..............................#",
			"#..gg.................gg.......#",
			"#..gg......R..........gg.......#",
			"#..hhh....########....hhh......#",
			"#..hhh....########....hhh......#",
			"#.........########.............#",
			"#..............................#",
			"#tt########################tt###",
			"################################",
		],
		"sorties": {"2": ["vieux_lyon", 1, 9]},
	},
}

static func zone(id: StringName) -> Dictionary:
	return ZONES.get(id, ZONES[&"presquile"])

static func case_a(id: StringName, position: Vector2i) -> String:
	var plan: Array = zone(id)["plan"]
	if position.y < 0 or position.y >= plan.size():
		return "#"
	var ligne: String = plan[position.y]
	if position.x < 0 or position.x >= ligne.length():
		return "#"
	return ligne[position.x]

static func est_traversable(id: StringName, position: Vector2i) -> bool:
	return not BLOQUANTS.contains(case_a(id, position))

static func accepte_pnj(id: StringName, position: Vector2i) -> bool:
	return SOLS_PNJ.contains(case_a(id, position))

## Les deux bouts d'une traboule : on sort par l'autre.
static func autre_traboule(id: StringName, depuis: Vector2i) -> Vector2i:
	var plan: Array = zone(id)["plan"]
	for y in plan.size():
		var ligne: String = plan[y]
		for x in ligne.length():
			if ligne[x] == "T" and Vector2i(x, y) != depuis:
				return Vector2i(x, y)
	return depuis

## Taille de la zone en pixels, pour borner la camera.
static func taille_pixels(id: StringName) -> Vector2i:
	var plan: Array = zone(id)["plan"]
	return Vector2i(int(plan[0].length()) * TAILLE_CASE, plan.size() * TAILLE_CASE)
