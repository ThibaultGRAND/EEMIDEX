class_name Zones
extends RefCounted
## Les 4 zones du MVP, decrites en texte. Une ligne = une rangee de cases.
## world.gd construit les TileMapLayer a partir de ces plans.
##
## Le quartier de la Confluence, parcouru du nord au sud : la gare de Perrache,
## le faubourg Sainte-Blandine, le bassin de la darse, puis la pointe sud et le
## Musee des Confluences. La Saone coule a l'ouest (a gauche), le Rhone a l'est
## (a droite), les deux se rejoignent en bas de la derniere zone, et les voies
## ferrees descendent au milieu du quartier.
##
## Legende :
##   #  batiment / mur (bloquant)     .  pave           ,  pave use
##   m  pave mousse                   q  dalle de quai  d  terre
##   w  eau (bloquant)                s  sable          p  ponton de bois
##   h  herbe courte                  g  herbe haute (rencontres)
##   t  arbre (bloquant)              j  buisson (bloquant)
##   b  ballast                       v  voie ferree (bloquant)
##   =  passage a niveau              L  lampadaire (bloquant)
##   n  banc public (bloquant)
##   S  soin      B  boutique     M  entrainement
##   T  passage sous les voies   R  ressource    X  combat de fin
##   1 2 3  sortie vers une autre zone

## Tous les plans font 32 caracteres de large ; la hauteur varie d'une zone a
## l'autre, la camera suit le joueur et se borne sur taille_pixels().
const LARGEUR := 32
const TAILLE_CASE := 16

## Cases que le joueur ne peut pas traverser.
const BLOQUANTS := "#wtvjLn"

## Sols simples ou les PNJ ont le droit de se balader (pas d'herbe haute,
## de passage sous les voies, de sortie ni de lieu special).
const SOLS_PNJ := ".,mqhsd"

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
	"p": [IMPORT, Vector2i(5, 2)],      # planches de ponton
	"b": [IMPORT, Vector2i(7, 1)],      # ballast, au bord des voies
	"v": [IMPORT, Vector2i(2, 10)],     # rail et traverses, sur ballast
	"=": [IMPORT, Vector2i(0, 11)],     # passage a niveau
	"j": [IMPORT, Vector2i(5, 0)],      # herbe, sous le buisson
	"L": [IMPORT, Vector2i(0, 0)],      # pave, sous le lampadaire
	"n": [IMPORT, Vector2i(0, 0)],      # pave, sous le banc
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

## Variantes d'un meme sol. Un grand aplat de la meme tuile se voit
## immediatement : on en pioche une au hasard, mais toujours la meme pour une
## case donnee, sinon le decor scintillerait a chaque repeinte.
const VARIANTES := {
	".": [Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	",": [Vector2i(1, 0), Vector2i(1, 0), Vector2i(0, 0), Vector2i(2, 0)],
	"q": [Vector2i(3, 0), Vector2i(3, 0), Vector2i(3, 0), Vector2i(2, 1)],
	"d": [Vector2i(4, 0), Vector2i(4, 0), Vector2i(0, 1), Vector2i(1, 1)],
	"w": [Vector2i(7, 0), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],
	"b": [Vector2i(7, 1), Vector2i(7, 1), Vector2i(3, 1)],
}

## Volume pose sur la couche du haut, triee en profondeur.
const DECORS := {
	"#": [PLACEHOLDER, Vector2i(0, 2)],   # mur : planche 5 a refaire
	"t": [PLACEHOLDER, Vector2i(5, 2)],   # arbre : planche 9 jamais recue
	"S": [PLACEHOLDER, Vector2i(6, 3)],   # croix de soin
	"B": [PLACEHOLDER, Vector2i(5, 3)],   # enseigne de boutique
	"X": [PLACEHOLDER, Vector2i(7, 3)],   # le gardien de la pointe
	"M": [IMPORT, Vector2i(7, 13)],       # borne d'entrainement
	"T": [IMPORT, Vector2i(6, 13)],       # bouche du passage sous les voies
	"j": [IMPORT, Vector2i(1, 9)],        # buisson rond
	"L": [IMPORT, Vector2i(5, 11)],       # lampadaire, pied en fonte
	"n": [IMPORT, Vector2i(7, 11)],       # banc public
}

## Partie haute des volumes qui font deux cases, posee sur la case du dessus.
const DECORS_HAUT := {
	"#": [PLACEHOLDER, Vector2i(1, 2)],
	"t": [PLACEHOLDER, Vector2i(6, 2)],
	"L": [IMPORT, Vector2i(6, 11)],       # lampadaire, tete et lanterne
}

const ZONES := {
	&"perrache": {
		"titre": "Perrache — la gare et les voûtes",
		"ressource": &"praline",
		"tuile_ressource": Vector2i(3, 13),
		## Pas d'herbe haute a Perrache : on ne croise rien sur le parvis.
		"rencontres": [],
		"niveau_min": 3,
		"niveau_max": 5,
		"depart": Vector2i(12, 10),
		"plan": [
			"www##########################www",
			"wwwqqt,,,L,,,,,,,,,,R,L,,,,qqwww",
			"wwwqq,,S,T,n,,,n,,,,,,,,B,tqqwww",
			"wwwqq####################..qqwww",
			"wwwqq####################..qqwww",
			"wwwqq####################..qqwww",
			"wwwqq####################..qqwww",
			"wwwqq####################..qqwww",
			"wwwqq####################..qqwww",
			"wwwqq....T...........L.....qqwww",
			"wwwqq.........L............qqwww",
			"wwwqq..,.........bvvb......qqwww",
			"wwwqq##,####..###bvvb######qqwww",
			"wwwqq##,####..###bvvb######qqwww",
			"wwwqq##,####..###bvvb######qqwww",
			"wwwqq##,####..###====######qqwww",
			"wwwqq..,....L....bvvb......qqwww",
			"wwwqq..,j,,j.....bvvb......qqwww",
			"wwwqq##,,,,,..###bvvb######qqwww",
			"wwwqq##,,R,,..###bvvb######qqwww",
			"wwwqq##,,,n,..###====######qqwww",
			"wwwqq##,,,,,.L###bvvb######qqwww",
			"wwwqq......................qqwww",
			"www#########22###vvvv########www",
		],
		"sorties": {"2": ["sainte_blandine", 12, 1]},
		## PNJ qui se baladent dans toute la zone. Cles optionnelles :
		## "case" (depart fixe, sinon une case libre au hasard) et "rayon"
		## (distance max a sa case de depart, sinon aucune limite).
		"pnj": [
			{"nom": "PnjSeb", "sprite": "res://assets/sprites/pnj_seb.png"},
			{"nom": "PnjThibaut", "sprite": "res://assets/sprites/pnj_thibaut.png"},
		],
	},

	&"sainte_blandine": {
		"titre": "Sainte-Blandine — le faubourg et le quai Rambaud",
		"ressource": &"cocon",
		"tuile_ressource": Vector2i(4, 13),
		"rencontres": [&"generique_gone", &"generique_traboulin"],
		"niveau_min": 4,
		"niveau_max": 7,
		"depart": Vector2i(12, 1),
		"plan": [
			"www#########11###############www",
			"wwwqqt,,,,L,..,,,bvvb,,,,,tqqwww",
			"wwwqq,,,,,,,..,,,bvvb,,L,,,qqwww",
			"wwwqq,t,,,,,..,,,bvvb,,,,t,qqwww",
			"wwwqq............bvvb......qqwww",
			"wwwqq.####....###bvvb......qqwww",
			"wwwqq.####....###bvvb......qqwww",
			"wwwqq.####....###bvvb......qqwww",
			"wwwqq.####....###bvvb......qqwww",
			"wwwqqj,n,,j...###bvvb......qqwww",
			"wwwqq,,,,,,....M.bvvb......qqwww",
			"wwwqq####........====.t..t.qqwww",
			"wwwpp####..,.....bvvbggggggqqwww",
			"wwwpp####..,..###bvvbggggggqqwww",
			"wwwpp.t..t.,L.###bvvbggggggqqwww",
			"wwwqqgggggg,..###bvvbggggggqqwww",
			"wwwqqgggggg,..###bvvbgggRggqqwww",
			"wwwqqgggggg,.....bvvbggggggqqwww",
			"wwwqqggRggg,.....bvvbhhhhhhqqwww",
			"wwwqqgggggg,.....bvvbhhhhhhqqwww",
			"wwwqqgggggg,.L..TbvvbT.....qqwww",
			"wwwqqhhhhhh,.....bvvb......qqwww",
			"wwwqqhhhhhh,.....====......qqwww",
			"wwwqqhhhhhh,.....bvvbhhhhhhqqwww",
			"wwwqq......................qqwww",
			"www#########22###vvvv########www",
		],
		"sorties": {"1": ["perrache", 12, 22], "2": ["darse", 12, 1]},
		## PNJ qui se baladent dans toute la zone. Cles optionnelles :
		## "case" (depart fixe, sinon une case libre au hasard) et "rayon"
		## (distance max a sa case de depart, sinon aucune limite).
		"pnj": [
			{"nom": "PnjThomas", "sprite": "res://assets/sprites/pnj_thomas.png"},
			{"nom": "PnjTheophile", "sprite": "res://assets/sprites/pnj_theophile.png"},
		],
	},

	&"darse": {
		"titre": "La Darse — le bassin de la Confluence",
		"ressource": &"quenelle",
		"tuile_ressource": Vector2i(5, 13),
		"rencontres": [&"generique_quenellon", &"generique_gone"],
		"niveau_min": 7,
		"niveau_max": 10,
		"depart": Vector2i(12, 1),
		"plan": [
			"www#########11###############www",
			"wwwqq,,,,,,,..,,,bvvb,,,,,,qqwww",
			"wwwqq,,,L,,,..,,,bvvb,,,,,,qqwww",
			"wwwqq###.###L....bvvb......qqwww",
			"wwwqq###.###.....====......qqwww",
			"wwwqq###.###.....bvvb......qqwww",
			"wwwqqqqqqqqq..###bvvb######qqwww",
			"wwwqqqqqqqqq..###bvvb######qqwww",
			"wwwqqwwwwwww..###bvvb######qqwww",
			"wwwqqwwwwwww..###bvvb######qqwww",
			"wwwqqpppppww.n###bvvb######qqwww",
			"wwwqqwwwwpww..###bvvb######qqwww",
			"wwwwwwwwwpww..###bvvb......qqwww",
			"wwwwwwwwwpww...R.====......qqwww",
			"wwwwwwwwwpww.....bvvb......qqwww",
			"wwwwwwwwwpww.....bvvb......qqwww",
			"wwwqqpppppww....TbvvbT.....qqwww",
			"wwwqqwwwwwww.....bvvb.t..t.qqwww",
			"wwwqqwwwwwww..gggbvvbhhhhhhqqwww",
			"wwwqqwwwwwww..gggbvvbhhhhhhqqwww",
			"wwwqqqqqqqqq..gggbvvbhhRhhhqqwww",
			"wwwqqqqqqqqq..gggbvvbhhhhhhqqwww",
			"wwwqqtgggggg..j..bvvbggggggqqwww",
			"wwwqqggggggg.....bvvbggggggqqwww",
			"wwwqqggggggg.L...bvvbggggggqqwww",
			"wwwqqggggggt....jbvvbggggggqqwww",
			"wwwqq......................qqwww",
			"www#########22###vvvv########www",
		],
		"sorties": {"1": ["sainte_blandine", 12, 24], "2": ["pointe", 12, 1]},
		## PNJ qui se baladent dans toute la zone. Cles optionnelles :
		## "case" (depart fixe, sinon une case libre au hasard) et "rayon"
		## (distance max a sa case de depart, sinon aucune limite).
		"pnj": [
			{"nom": "PnjJulian", "sprite": "res://assets/sprites/pnj_julian.png"},
			{"nom": "PnjEmile", "sprite": "res://assets/sprites/pnj_emile.png"},
		],
	},

	&"pointe": {
		"titre": "La Pointe — le musée et le confluent",
		"ressource": &"cocon",
		"tuile_ressource": Vector2i(4, 13),
		"rencontres": [&"generique_traboulin", &"generique_quenellon"],
		"niveau_min": 10,
		"niveau_max": 13,
		"depart": Vector2i(12, 1),
		"plan": [
			"www#########11###############www",
			"wwwqqthhhthh..hhhbvvbhthhhtqqwww",
			"wwwqqhhhhhhh..hhhbvvbhhhhhhqqwww",
			"wwwqqggggggh..hhhbvvbggggggqqwww",
			"wwwqqggggggh..hhhbvvbggggggqqwww",
			"wwwqqgggRggh..hhhbvvbggggggqqwww",
			"wwwqqggggggh..hhhbvvbggRgggqqwww",
			"wwwqqggggggh..hhhbvvbggggggqqwww",
			"wwwqqhthhhhh..hhhbbbbhhhhthqqwww",
			"wwwqqgtggggg.....bbbb......qqwww",
			"wwwqqggggggqqqqqqqqqqgtggggqqwww",
			"wwwqqggggggq########qggggggqqwww",
			"wwwqqgggggtq########qggggggqqwww",
			"wwwqqggtgggq########qggggtgqqwww",
			"wwwqq......q########q......qqwww",
			"wwwqq......q########q......qqwww",
			"wwwqq......q########q......qqwww",
			"wwwqq......LqqqqqqqqL......qqwww",
			"wwwqq......qqqqqqqqqq......qqwww",
			"wwwwwwwwwqqqqqqqqqqqqqqwwwwwwwww",
			"wwwwwwwwwhthhhhhhhhhhthwwwwwwwww",
			"wwwwwwwwwhgggggggggggghwwwwwwwww",
			"wwwwwwwwwhgggggggggggghwwwwwwwww",
			"wwwwwwwwwwwwwwsssswwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwsXsswwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwsssswwwwwwwwwwwwww",
		],
		"sorties": {"1": ["darse", 12, 26]},
		## PNJ qui se baladent dans toute la zone. Cles optionnelles :
		## "case" (depart fixe, sinon une case libre au hasard) et "rayon"
		## (distance max a sa case de depart, sinon aucune limite).
		"pnj": [
			{"nom": "PnjPaloma", "sprite": "res://assets/sprites/pnj_paloma.png"},
			{"nom": "PnjGuillaume", "sprite": "res://assets/sprites/pnj_guillaume.png"},
		],
	},
}

## Variante de sol a poser sur une case. Le tirage depend des coordonnees,
## donc il ne change pas d'une repeinte a l'autre.
static func sol_de(c: String, cellule: Vector2i) -> Array:
	if not VARIANTES.has(c):
		return SOLS.get(c, [0, Vector2i(0, 0)])
	var choix: Array = VARIANTES[c]
	var melange := (cellule.x * 73856093) ^ (cellule.y * 19349663)
	return [SOLS[c][0], choix[absi(melange) % choix.size()]]

static func zone(id: StringName) -> Dictionary:
	return ZONES.get(id, ZONES[&"perrache"])

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

## Les deux bouts d'un passage sous les voies : on sort par l'autre.
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
