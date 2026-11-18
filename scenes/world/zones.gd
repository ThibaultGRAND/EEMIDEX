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
##   =  passage a niveau              L  lampadaire (traversable)
##   r  rails de tram (traversable, les tramways y circulent)
##   n  banc public (bloquant)
##   S  soin      B  boutique     M  entrainement
##   T  passage sous les voies   R  ressource    X  combat de fin
##   1 2 3  sortie vers une autre zone

## Tous les plans font 32 caracteres de large ; la hauteur varie d'une zone a
## l'autre, la camera suit le joueur et se borne sur taille_pixels().
const LARGEUR := 128
const TAILLE_CASE := 16

## Cases que le joueur ne peut pas traverser.
const BLOQUANTS := "#wtvjn"

## Sols simples ou les PNJ ont le droit de se balader (pas d'herbe haute,
## de passage sous les voies, de sortie ni de lieu special).
const SOLS_PNJ := ".,mqhsd"

## Source unique du TileSet assets/tilesets/placeholder_tuiles_hd.tres : tuiles
## 64x64 dessinees par tools/generer_tuiles_hd.py, affichees a scale 0.25 (16 px dans
## le monde). Les tuiles de l'equipe (lyon.tres, 16 px) restent dans le depot.
const TUILES := 0
## Anciens noms des sources, gardes pour le code qui les cite encore.
const IMPORT := TUILES
const PLACEHOLDER := TUILES

## Sol pose sur la couche du bas : caractere -> [source, case de l'atlas].
const SOLS := {
	"#": [TUILES, Vector2i(0, 1)],      # terre, sous les batiments
	".": [TUILES, Vector2i(0, 0)],      # pave lyonnais
	",": [TUILES, Vector2i(3, 0)],      # pave use
	"m": [TUILES, Vector2i(5, 0)],      # pave avec mousse
	"q": [TUILES, Vector2i(6, 0)],      # dalle de quai
	"d": [TUILES, Vector2i(0, 1)],      # terre et gravier
	"h": [TUILES, Vector2i(2, 1)],      # herbe courte
	"g": [TUILES, Vector2i(4, 1)],      # herbe haute : declenche les rencontres
	"w": [TUILES, Vector2i(5, 1)],      # eau
	"s": [TUILES, Vector2i(0, 2)],      # sable de berge
	"t": [TUILES, Vector2i(2, 1)],      # herbe, sous l'arbre
	"p": [TUILES, Vector2i(1, 2)],      # planches de ponton
	"b": [TUILES, Vector2i(2, 2)],      # ballast, au bord des voies
	"v": [TUILES, Vector2i(4, 2)],      # rail et traverses, sur ballast
	"=": [TUILES, Vector2i(5, 2)],      # passage a niveau
	"r": [TUILES, Vector2i(6, 6)],      # rails de tram, pris dans le pave : on marche dessus
	"j": [TUILES, Vector2i(2, 1)],      # herbe, sous le buisson
	"L": [TUILES, Vector2i(0, 0)],      # pave, sous le lampadaire
	"n": [TUILES, Vector2i(0, 0)],      # pave, sous le banc
	"S": [TUILES, Vector2i(7, 2)],      # dalles de place sous les lieux speciaux
	"B": [TUILES, Vector2i(7, 2)],
	"M": [TUILES, Vector2i(7, 2)],
	"T": [TUILES, Vector2i(7, 2)],
	"R": [TUILES, Vector2i(2, 1)],      # l'objet a ramasser est en decor
	"X": [TUILES, Vector2i(7, 2)],
	"1": [TUILES, Vector2i(6, 2)],      # marqueur de sortie grave au sol
	"2": [TUILES, Vector2i(6, 2)],
	"3": [TUILES, Vector2i(6, 2)],
}

## Variantes d'un meme sol. Un grand aplat de la meme tuile se voit
## immediatement : on en pioche une au hasard, mais toujours la meme pour une
## case donnee, sinon le decor scintillerait a chaque repeinte.
const VARIANTES := {
	".": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	",": [Vector2i(3, 0), Vector2i(4, 0)],
	"q": [Vector2i(6, 0), Vector2i(6, 0), Vector2i(7, 0)],
	"d": [Vector2i(0, 1), Vector2i(1, 1)],
	"h": [Vector2i(2, 1), Vector2i(3, 1)],
	"t": [Vector2i(2, 1), Vector2i(3, 1)],
	"j": [Vector2i(2, 1), Vector2i(3, 1)],
	"w": [Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1)],
	"b": [Vector2i(2, 2), Vector2i(3, 2)],
}

## Volume pose sur la couche du haut, triee en profondeur. Les batiments ("#")
## ne sont pas ici : decor_batiment() choisit facade, toit ou bord selon les voisins.
const DECORS := {
	"t": [TUILES, Vector2i(0, 5)],        # arbre : tronc et bas du feuillage
	"S": [TUILES, Vector2i(6, 5)],        # panneau de soin
	"B": [TUILES, Vector2i(7, 5)],        # etal de boutique
	"X": [TUILES, Vector2i(2, 6)],        # le gardien
	"M": [TUILES, Vector2i(0, 6)],        # borne d'entrainement
	"T": [TUILES, Vector2i(1, 6)],        # bouche du passage sous les voies
	"j": [TUILES, Vector2i(2, 5)],        # buisson rond
	"L": [TUILES, Vector2i(3, 5)],        # lampadaire, pied en fonte
	"n": [TUILES, Vector2i(5, 5)],        # banc public
}

## Partie haute des volumes qui font deux cases, posee sur la case du dessus.
const DECORS_HAUT := {
	"t": [TUILES, Vector2i(1, 5)],        # haut du feuillage
	"L": [TUILES, Vector2i(4, 5)],        # lampadaire, tete et lanterne
}

## Tuiles des ressources a ramasser, par ressource.
const TUILES_RESSOURCES := {
	&"praline": Vector2i(3, 6),
	&"cocon": Vector2i(4, 6),
	&"quenelle": Vector2i(5, 6),
}

## Facades du rang du bas d'un batiment, tirees de facon stable par case.
const FACADES := [Vector2i(0, 3), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]
const FACADE_GAUCHE := Vector2i(4, 3)
const FACADE_DROITE := Vector2i(5, 3)
const TOIT := Vector2i(0, 4)
const TOIT_GAUCHE := Vector2i(1, 4)
const TOIT_DROITE := Vector2i(2, 4)
const TOIT_HAUT := Vector2i(3, 4)
const TOIT_HAUT_GAUCHE := Vector2i(4, 4)
const TOIT_HAUT_DROITE := Vector2i(5, 4)

const ZONES := {
	&"perrache": {
		"titre": "Perrache — la gare et les voûtes",
		"ressource": &"praline",
		"tuile_ressource": Vector2i(3, 13),
		## Pas d'herbe haute a Perrache : on ne croise rien sur le parvis.
		"rencontres": [&"thigoat", &"seb", &"thibouclier"],
		"niveau_min": 3,
		"niveau_max": 5,
		"depart": Vector2i(64, 31),
		"plan": [
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqhgbbbqqqqqqqqqqqqqqqqq,,,...#######qqqqwgqqqqrrqqq##########qqqqq##qqqqqqqqqqwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqg,,,,,..,,...,,,,,,,,,,,###########...qwq.#....r..##########...,.##...,,,,,,qwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..,,.,...,,...,,,,,,,,,,,###########....hm###.,,,rrr.##########,,,###..,,,,,,qwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.,,,,L,,,,,,,.,,,,,,,,,,,###########.####.####,,,,,,rrrrr...###,,L##..,L,,,,,qwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.,,,.,,,,,,,,,,,,,,,,,,,,,################.###########.,,,,rrrrrrr.#.,,.,,,,,.qwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqg.,,.,.,,g,,,,,,,,,,,,,,,,,############################,,,,,,,,,,,,,rrrrrr,,,,.qwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqgh.,,,.,,,,,,,,,,,,,,,,,,,,#############################,,,,,,,,,,,,,,,,,,rrrrrrrwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqhg,,,.,,,,,,,,,,,,,,,,,,,,,#############################,,,,,,,,,,,,,,,,,,,,,,,,qwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwhh,,,##...,,,,,,hghhghg,,,,,,,,,########################,,,,,,,,,,g,,,hgh.,,,,,,qwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbL,,###,#####...m,,,mRggghg,,,,,,,,,.##.################,,,,,,,,,gh,,,Rhmg,,,,,,qwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwvbbbb###,###########.,,,,,,,.,,,,,,,,.##.####.###########,,,,,,,,,,,,,,ghg,,,,,,,qwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwvv=vvb##bbbb..###########.##.,,.....,,....####.##.,.######,,,,,,,,,,,,,,hg,,,,,,,qwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwbbv=vvvvvvvvbbbbbb..######.#####.L,,,.,gg.####..##.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,qwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqbbbvvvvvvvvvvvvvbbb#####..#####,,..,..mh.####.....,,,,,,,,,,,,,,,,,,,,,,,,,h,,,,qwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..,bbvvvvvvvvvvvvvvvvv###b######,,gg..thm.###...m.,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,.qwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq...,,###vvvvvvvvvvvvvvvvvvvbbb.##L,,gggh..####.,Lh,L,.,.....L,,,,,,,,,,,,,,,,,,,.,qwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwg..,,#####vvvvvvvv#vvvvvvvvvvvb,,...,,,,,..###.....,g,,,#####.......,,,.,,,,,,,,,.qwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqhm.,,####bbvvvvvvvvvvvvvvvvvvvb,.,,.....,,.###......g,,,#####.....,#......,,,,,,..qwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqq...,,#####,b##vvvvvvvvvvvvvvvvvbb###....L,..#.L,.ggghg,,,#####.....,#######.,,,,,.,qwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqhg..,.#####,###vvvvvvvvvvvvvvvvvb#######...###.,.,,,,,,.,,#####....,,#######..,,,,,qwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqgh..,,.#####,####vvvvvvvvvvvvvvvvv##############,....,.##,#####.....,##########,,,,,qwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqhg....,,,.#,,#####vvvvvvvvvvvvvvvvvvvv###########.......#.,,,,#.....,##########,,,,,qwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqhgm.,,###.,,..######vvvvvvvvvvvvvvvvv##vvvv##########.......##,,,,..,,##########,,,,qwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwhgg.,,.######..,,,.##vvvvvvvvvvvvvvv#vvvvv#vvvvv###########.bb#####,...#########,,,,,qwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqgg.L,,#######,####,.bbvvv#vvvvvvvv#vvvvv#vvvvvvvvvvv#########vv#######,,,,,#####,,,,,qwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqgg.,,#######,,####.g#bbvvv##vvvv#vvvvv#vvvvv#vvvv##vvvv######vvvvv#vbbbbb..,,,##,,,,qwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwqm...,.#######,##g##.g##bvvv####vvvvv##vvvv#vvvvv#vvvvv#vvvvv#vvvvvvvvvvvvbbb..#,.,,,,qwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwqghm.,,########,##...g.hgbbvv#######vvvvvv#vvvvv#vvvvv#vvvv##vvvv##vvvvvvvvvvbbb##.,,,,qwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwqh...,,,######.,#######g##bvvv######bb##vvvvvv#vvvvv#vvvvv#vvvv##vvvv##vvvvvvvvvbbb,,,qwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwqhg..,,########,..###.#####bv#v#####b,######vvvvvv#vvvvvv#vvvvvvvvvv#vvvvv##vvvvvvvbbb,qwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwqh...,##,...###,...h..#######vvv###bb,######bbb#vvvvvv#vvvvv#vvvvvvvvvvvvvvvvvvvvvvvvbbbwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwqhg..,,###.........h.hgg.g#b##v#v##bb,,#######..bb#r#vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv=vvwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwqgm..,####.....,,.m.ggg.gghb##v#vBbbb,.#######..t.r.####bvvvvvvvvvvvvvvvvvvvvvvvvvvvvv=vwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwqgg..,L####....L,.......ghhb###v#vqbbb,#######T....r.....bb##vvvvvvvvvvvvvvvvvv####vvvv=vwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwqg..,,...#......,........m.bvvvv#vvbbb.##S####....r......t..#bbbbbbbbbb#bb#########bbbbbbwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwqgg..,,,,,,......,..........bvvvvv#vbbT,##.######..r...........##,,,,...#,##########,,,,,qwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwqmh.L,.#...,,,,,L............bvvvvv#vbb,L##.#.####.r.......t....######,,,L,#######.##,,,,qwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwqhm..,.#####...,,,.,.........bbvvvv#vbb,......####.r.####.......#########..,,,.###...,,,,qwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwq.h..,,#########..,,,,,,......b##vvv#vqb,#...#####....#######....#########,###.,,,...,,,,,qwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwqm..L,.##########,,L..L,,,,,L..b####vvb,,###.#####.rq##########,##########,######.,,.,,,,,qwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwq.gm.,,###########,.....#...,,,,,..bb==b,##########qrq##########,##########,##..##.###,,,,qwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwqgh..,############,.....#.###..,,,,,bvvb,##########qr.####################.,##..#####.,,,,qwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwqgg..,.############,##....####,###..bbvvb..########.rq.####################,.....#.###,,,,,qwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwggg..,############,,##..#.####,######vvvb.,,,..####.r.#####################,.......###,,,,qwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwpwwqgh..,.############,##.....###.,######vvvb..,,,,,....r.####################..........#,,,,,qwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwppp.gg..,.############,##......##,#######vvvb###..,,,,..r..########,##########,.........#,,,,,qwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwq.g..,..###########,,##......##,#######vvbb####,##..Rr,.,,..#####,##########,#.......##,,,,qwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwq....,,.############,.#......###,######vvvb#####,.###,r..,,,,,,...,####.#####,##......##,,,,qwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwq#.L,.,m,,,,########,##......##,,######vvvb##########,r,##...,,,,.,.....####..##......#L,,,,qwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwww###...,,hg.,,,,,,####,##..##..##,######vvvvb#########,,r,######...,,,,,....##,##......##,,,,qwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwww###.,.,hh......,,,,,..#...##.###,######vvvbb#########,r,.#########...,,,,,....####...###,,,,qwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwww###....,g#####..,##..,L,...##.##.,#######vvb##########,r,##########,####..,,,.,L.....####,,,,qwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwww###.,..,g##.####,##.....,,,,..##,#####bv#vvb##########,r,#########,,####.##..,,,,,,...##.,,,,qwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwq##....,.h#.,.....####......,,,,..#####bvvvbb#########,,,.#########,#####,####.....,,,,,..,,,qwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwq##.,..,g##.gg,.,####......##...,,L,.##bvvvb##########,r,##########,##########,####...,,,,,,,qwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwq.mhgg..,g##,hh..,..##,.....#####...,,,,bbbvb####,#####,r,##########,##########,########..,,,,qwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwqtghgt.,,g##,hgm#.....,........##,.###..,bbvb####,####,,,,##..#####,,####################.,,,,qwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwqghhghg.,gh#.,g,.#,...,.........##,#######bvbb,,,#.####,r,.###..####,#####################.,,,qwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwhghgggg.,g##.gg,##,....##...#####,,########vb#.,...,.#..r,####......,#####################.,,,qwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwghgggg..,h##,gg.##...,.##.##.####,.########v##..#,##,,.,r.#####..#..,####################.,,,,qwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwgggghgh.,,g#.,h,.#,...,##..##.....,########v###.##,####.rr.,,######.,#####################.,,,qwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwhgggghg.,g##.,g,##,....##..###....,.#######v#####,,####2r,...,,,,##.,....,################.,,,qwwwwwwwwwwwwwwwwwwwwww",
		],
		"sorties": {"2": ["sainte_blandine", 66, 1]},
		## Alternants sauvages qui se baladent. Cles optionnelles :
		## "case" (depart fixe, sinon une case libre au hasard), "rayon"
		## (distance max a sa case de depart, sinon aucune limite) et "gone"
		## (sa fiche dans data/gones, sinon un sauvage au hasard).
		"pnj": [
			{"nom": "Thigoat", "frames": "res://assets/characters/pnj_thibaut/pnj_thibaut_frames.tres", "gone": &"thigoat"},
			{"nom": "Seb", "frames": "res://assets/characters/pnj_seb/pnj_seb_frames.tres", "gone": &"seb"},
		],
	},

	&"sainte_blandine": {
		"titre": "Sainte-Blandine — le faubourg et le quai Rambaud",
		"ressource": &"cocon",
		"tuile_ressource": Vector2i(4, 13),
		"rencontres": [&"roulian", &"matiti", &"e1000"],
		"niveau_min": 4,
		"niveau_max": 7,
		"depart": Vector2i(66, 1),
		"plan": [
			"wwwwwwwwwwwqggghgh.,h.#.gh,##,..,.##.#######,.########v#####,#####1r,hthh...,,..####,################,,,,qwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwqhgggghg...m.,hg.#....,.##.##...##,#########v##.##,####.,r,ghgghgg.m..,,,..####,##########.,,,,qwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwggghggh.,gg..,.,.#....,##..##.....,########vb##..#,####,,,.ghgggghgh,###...,,##,##########.,,,qwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwqgghg.m.L,g#####.,##L,..##..######.,ggm#####vb##..,,####,r,L,gt..gthL,####,.#.,.L,#########,,,,qwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwqght.....,h##,###,.....###..#.####,ghghhghbbvb#...,#####,r,h,g.ghggm,,##..,####..,,,,.#####,,,,qwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwqhg.....,,g#.,..#.,.,,.#...##......gthgghgbvvb....,####,,r,g,.####hg,.###.,..##,#####,,,,#.,,,qwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwgh.t...L,hg#.,..hm.L,,L.#..##........hgtgtbvbb...,,####,r,gg.######g,###.,,..##,########.,.,,,qwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwqhgmgggg.,g##..ghghm.,...##........,###m..gbvb....,.####,r,g,g######g,##..,...##,##########,,,,qwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwqgt.g...m,g##,.hhgh......##..#....,.#######bvb...#,#####,r,.gg.gg##hg,##..,..##,,#########.,,,,qwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwqg..hm#L,hg#.,.gghgg,.....#.#####.,....####vbb..##.####,,r,ghh..gggg,###.L,..##,##########.,,,qwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwq.hmhh.#.,g##.,..ggm.,.......######,##....##vb####..,###,r,hghggg..m.,##..,,####,##########.,,,qwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwq.t.t....,g##........,...#..mhgh##,,##..####vb####...,,..r.ghgtgt.thm,##..,..##.,##########,,,,qwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwqg.......mh.####...L,...###..hgh##,.##.####vvb####,####L,rL,,Lhghhgh,##..L,....,##########.,,,qwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwght....,,,m..######.,.#####.gghggg,###.####v#####.,####,r....,,,,.h.,##...,....,##########.,,,qwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwgR.gg#...,,,,,...###,..###.mg####,,##...###v###########,r,#####..,,m.###.,###..,##########,,,,qwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwhg.g##.###...,,,,...,L......h####,.##...###v##.##,#####,r,#######....,,,L,.###L,#########.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwgt.g##########..,,,,,g...m...m..#,###.####vv#....,####,qr,###......,##....,...,##########.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwg.gh#.h...#######..,,,,,hg..t.t..,....####v##..##,####,rq.###..###.,#####.,,,..##########.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwhtgh#ggghg.m.######,#..L,,,mh...,,.t...###v##..##.R.##,rq####..####,#########..,,,,######,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwqm.h##gggghgghg..m#,####.#..,,,,,,...m...bvv##.##,...#,qr,####..###,##########,,##.,,,,##..,,,qwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwq.mg##ghgghgggghghm,##gg#####...,,.,hg...bvbb..##,#.##,qq.###...##..#######..#,#######.,,.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwq.gg#.hghhghgggghg.,##gg########...m,,,,gbvb.t.L,,####,rq.###...##.,#######m##,##########L,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwq.ghmhhghgggghgghg,,##g.##.gg###.,###...bbvb....,.####,r,.###..###.,#...,ggh#.,#########..,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwq..g..gghgggghghhgm,##gh.##gggg##,#######bvvb,,,,...##,,r,..#...###,##...,g###,##########.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwqt.g..gggghghhghgg.,###h##.ghgh##,#######bv##...,,,....r....##.####,#####,hggh,##########L,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwpp....t.....ghgghggg.,##hg##.gghg#.,######.bv#####...,,.,r,...#######,#..#,####.,##########,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwpwq....gg......ggghg,,##g.##.ggh##,,######bbv#####,###..,r,,,.M..#.#.,#...,####,,#########.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwpp....t...t.t.......,###g.##ghhg##,.######bvv####,,###L,r....T,,.....#####,g.##,##########L,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq..g..qq........t...###h##.ghgg##,###ggggbv######...#.,r,###...,,,.,...##,..##,##########.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq.ggggwwqq.,,........##.##.#####.,###hgtbbv#####,..##.,r,#######...,,,,.....#.,##########,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwqq..ghggwwwwq,,,,,L..........#####,,###gghbvv#####...##.,r,#########,....,,,.....#########L,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq...hghwwwwwq,##..,,,,.....t....##,####gh#bv######,..#.,r,.#########,####...,,,,,...######.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.mhhghwwwwwq,.#####...,,..........#######bv######,..#.,r,.#########,####,###...,,,,....##.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwqt.gghgwwwwwq......##.g#.,,,,L....,L..###bbv#####,L.##.,r,#########.,##.#,####.,....,,,,.L,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq..gggghwwwq,#####.#h.######.,,,.,...gh.Tbvv#####,..#..,,,#########,##...,####,,#####...,.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq..hgggwwwwq,#####.#gh..######,#.,.,.m...bvb#####,###.,r,##########,##..######,########...,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.ggghwwwwwq.hgh#.##.g#.#...##,#.,L.,,,,,bvb#####.###.,r,##########,##.#,#####,...#######,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.gghwwwwwwqgghgghgggg#####....,,,......bbvb.###,####.,r,#########.,#...,####,,#.....#.#.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.ghhgwwwwq,gghgggghghhgm#######,.......bvvb,,,..####.,,,#########,####,,####,####..#....,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwqmhggwwwwwq,hhghgggghgghgggg.###,L......bv##...,.,,,..r,##########,##########,#..#..####.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.hggwwwwwq.hgggghgghgggghghh##.,......,bv####.##..,.,r.##########,##########,#.......#.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.ghgwwwwq,###.ghg.hghgggghgg##,,......bbv#######.....r.,,,######,##########,.#.#.......,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.gggwwwwq,L######hgggghggh.###,L...R..bv##########..r,.##,,,,,##,##########,####..#....,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq...hwwwwq.....###gggghghhg....,......,bv#########..,r,######,,.,,####,#####,...#..####,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq....qqqq,###...##ghg#####gg...,......bbv#########..,r,...####..,,,,,..####,,#.......#.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq..t.t......###.##gm..#######.,L......bvv#########..,,.##...####..#.,.,.,L#,####..#....,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.h.m...t.t.....#.##......####,.......bv#########..,r,.#.#######,######,,,.,...#..####.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwqmghgg.......t..,.#######...#.,......bbv#########..,r,##.######.,#..#.###....,,,..#.#.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.ggghm..p............#######,,......bvv#########..,r.hg.ggh.##,,##...###.,L..L,,,,,L.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.###g..ppppppqqqq.t.......##,.......bv##....####..r,.##.t.g.##,##........,....###,,..,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwq.####..ppwpppwwwwqqq.t..............bv##.........,r,###g..###.,##.#...###,....###...,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwqq####qqppwpppwwwwwwwqqqq...,,......bbv##......##.,r,###hm###.,..#####.######.##..###.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwppwpppwwwwwwwwwwwqqqq..,,...bvv####...###.,r.##gh...#.....hgg#m..,###.###.##.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwpwwwwwwwwwwwwwwwwwqqq...,b=bb#####.###,r,###h.tg...,.##.m..hm.,....##..##.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwpwwwwwwwwwwwwwwwwwwwwqqqbbvb,,...#.###,r,###gmg...L,.##.####gh.##.....###.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwqqqqqqwwwwpwwwwwwwwwwwwwwwwwwwwwwwwvvbq..,,.....,r.###..g...,,.#..####.,##.####.....,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wpwq....qqqqqqwwwwwwwwwwwwwwwwwwwwwwwwwwwwqqq...,,.rr.#####....,....m####g,##hh###.##.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wpp..gghwqqqqqqqqqqwwwppwwwwwwwwwwwwwwwwwwwwwqq....r.....#####.,.....h##gg,##gghgg###.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wpp..gtgwwwwwwwq...qqqt.qwwwwwwwwwwwwwwwwwwwwwwqt..r..t......##,......ggg...hgggth###.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwp..hgggwwwwwwq###......qqqqqqwwwwwwwwwwwwwwwq....r.....................,.####ggg##..,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwqmgthgwwwwwq.#######........qqqqqwwwwwwwwwwq.t.r...t.t...t...,........,.#####mg##.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwq.ghghhwwwwq.##############......b=bqqqwwwwq...r...........,##2,,.....,gg..#.hhg..,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
		],
		"sorties": {"1": ["perrache", 66, 60], "2": ["darse", 65, 1]},
		## Alternants sauvages qui se baladent. Cles optionnelles :
		## "case" (depart fixe, sinon une case libre au hasard), "rayon"
		## (distance max a sa case de depart, sinon aucune limite) et "gone"
		## (sa fiche dans data/gones, sinon un sauvage au hasard).
		"pnj": [
			{"nom": "Roulian", "frames": "res://assets/characters/pnj_julian/pnj_julian_frames.tres", "gone": &"roulian"},
			{"nom": "E1000", "frames": "res://assets/characters/pnj_emile/pnj_emile_frames.tres", "gone": &"e1000"},
		],
	},

	&"darse": {
		"titre": "La Darse — le bassin de la Confluence",
		"ressource": &"quenelle",
		"tuile_ressource": Vector2i(5, 13),
		"rencontres": [&"palou", &"tortheo", &"cecissoussou"],
		"niveau_min": 7,
		"niveau_max": 10,
		"depart": Vector2i(65, 1),
		"plan": [
			"wwwq.gthggwwwwq.###################bb=b...qqqq....r.t.....t.t.,##1###,,,,....gghg.h..,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwqmhghhwwwwq#####################vvb.###......rr...........,##.###.##,........hg.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq.hghwwwwq.#####################v##########..r......t....,##.....###,.........m.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq.ghgwwwwq.#####################v###########.r.##......t.,##.#.....,.#.........L,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq..#ghwwwq######################v##########.qr.######.....##.###.##,.#..........,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq.###gwwq.#####################v###########.qq.#########,.,,..##.##,.#......R.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq.###qwwq.#####################v###########.rq.########.,###,,,,.##,..........L,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq.....qq..#####################v###########qr.#########.,###..#.,,............,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwq...m,,,....,.################vv##########.qr.#########,,.hg..####..,,,.......,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwq.h.qq..........#############vv##########.rq.#########,L####mhg...##..,,,,..L,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwqmgtwwqq,,,,.g,g,..#########vvv##########.r.#########.,.#######...##.#....,.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwq.gggwwwq.,,,,,.,......####bvv##########..r.#########,,#...####.gg######.##.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwq.hggwww####.#,,,...,g.....b==b#########....#########,##...####mh##...##.##L,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwq..hhgww####.##,g.,,,,,...bbvvb#########.r..########.,##...####.m.#.....###.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwq.hggwww######,.m,##.,,,,bvvbb....#####.r.#########.,##..####..........###,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwqmggwwww#####..gh,#####.bbvvb,g..m......r.#########,,....####...#......#.L,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwq.ghwwww#####,gg.,.######vvvb,,,,.h....rr.#########,###..####g.###.....##.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwqtggwwwwww###,hh,,.....#bvvvb##..,,,,..rrr.#######.,##...####..###....###.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwq.ghwwwww###.hg,#.....bbvvvb######.,.,r.rrrr..###.,##..####g.........##L,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwq.hgtwwww##,hgg,#.....bvvvvb###.####.rr,...rrrr..,..#...###g.g.#.....##.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwqm.Rgwwwwq..gg,,.....bbvvvvb....####,r,.,,,,,...r.###..........###..#...,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwq.t.tqqqq.t.t..,L....bvvvvvb##..####,r,....,,,,,,L#####..##.t.###...###.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwq..............,...Tbvvvvb###.#####,r,..R.....,,,,,..#..##...###...##.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwq.####.t.t.t..b.,,,bbvvvvb###.####,,,,............,,,,,....t.###..###.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwq.####.......,bbbbbbvvvvvb##..####,r,.............L,.L,,,....########.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwq.####....t.,bbv#bbvvvvvb,...####,r,...................g...,,..#####,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwq.####......bbbv#bvvvvvvb.,,,,...,r,...................gg...,,,,,..X.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwq.m##.......bbbv#vvvvvvvb.....,,.r,................#..mg.......,,,,.,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwqhhg......,bbbvbvvvvvvbb.......,r,................###hg............,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwqtgh.t....bbbbbbvvvvvvb........,r,................###ghm..........,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwqggm.....b#bbbvvvvvvvb........r,,L..............####gh...........,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwq.t.....,b##bbvvvvvvvb....t..,r,..................#.hT...........,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwq....##,,.bbbbvvvvvvvb.......,r,...................hgm..........,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwq.####,,,bbbbvvvvvvvb.......,r,L.................mgg...........,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwq.####.,,.bbbbvvvvvvb......,,,....................g............,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwq#####,,,bbbbvvvvvvb......,r,...................gg............,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwq.####.,,.bbbvvvvvvbb.....,r,L...................g............,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwq#####,,,bbbbvvvvvvb.....,r,..............#.................,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwq.####q,,.bbvvvvvvvb.....,r,..............#.................,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwq.##qwwq,,bbbvvvvvvb...g,,r,................................,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwq...qwq.,.bbvvvvvvb..gh,,,,.............................,.,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwq....q.,,.bbvvvvvvbb.hg,r,........................t...t...,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwq...#.L,,bbbvvvvvvb.hg,r,......................#...#....,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwq.###..,,.bbvvvvvvbmgh,r,.....................#########.,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwq####.,,,bbvvvvvvb.m..r,...m...m...mg..###...#########.,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwq.###..,,.bvvvvvvbb.m,r,..hgggghghhgh.#####..#########,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwq.####...,bbvvvvvvb.h,r,gtgghthtghgggm#####..#########,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwq.###...,bbvvvvvvb.g,r,.gggghgghgggg.#####.g########.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwq.......,bbvvvvvvbbg.r,Lghgghgmgghg.#####.mhgghg####.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwq.t..#,,hbbvvvvvvbh.,r,hghhghgggghm#####.hthtghggg#,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwq...###,.bbvvvvvvbbg,r,hgtgggghgghg..###.h.hggggh..,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwqt..##,,gbvvvvvvvbg,r,ghgggghthhg..gg..mg..g.thth.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwq..###.,.bvbvvvvvbb,r,.gghghh.hgg####g..,,,hghhgh.,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwq.####,.bbbvvvvvvb.r,.ggthg.tggg###hh,,...,,,,hg,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwq..###.,gbbbvvvvvbb,r,hgghgg.gh####hL,.......L,.,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwq..####,.gbbvvvvvvb,r,mhtgtgtgg####..,..........,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwq.####.,gbbbvvvvvbbr,.m...ghgghggg.,,.........,,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwq..####,.gbbvvvvvvb,r,L....ghhghggg,..........,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwq.####.,gbbbvvvvvb,r,......hggggh.,..........,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwq..####,.gbbvvvvvbb,r,......ggghg.,..........,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwq.####,,ghbbvvvvvb,r,.......mhhg,,L........,,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwq..####,.g.bvvvvvbb,r,........g.,.........222,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
		],
		"sorties": {"1": ["sainte_blandine", 65, 60], "2": ["pointe", 67, 1]},
		## Alternants sauvages qui se baladent. Cles optionnelles :
		## "case" (depart fixe, sinon une case libre au hasard), "rayon"
		## (distance max a sa case de depart, sinon aucune limite) et "gone"
		## (sa fiche dans data/gones, sinon un sauvage au hasard).
		"pnj": [
			{"nom": "Palou", "frames": "res://assets/characters/pnj_paloma/pnj_paloma_frames.tres", "gone": &"palou"},
			{"nom": "Tortheo", "frames": "res://assets/characters/pnj_theophile/pnj_theophile_frames.tres", "gone": &"tortheo"},
		],
	},

	&"pointe": {
		"titre": "La Pointe — le musée et le confluent",
		"ressource": &"cocon",
		"tuile_ressource": Vector2i(4, 13),
		"rencontres": [&"thomasu", &"paguera", &"guignome"],
		"niveau_min": 10,
		"niveau_max": 13,
		"depart": Vector2i(67, 1),
		"plan": [
			"wwwwwwwwwwwwwwwwwwwwwwwwwq.####,,hgbvvvvvvb,r,..........,.........111,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwq..####,ghbbvvvvvbb,r,........,,.........,,,,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwq..###...hgbvvvvvvb,rr........,..........,,,,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwq.##.....mbbvvvvvbb,r,.......,L........L,,,,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwq......,,,.bvvvvvvb.,r,......,..........,,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwq.t.t..,..bbvvvvvb.,,,..,...,.........,,,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwq......,.,Lbvvvvvb##,r,mh...,........L,,,,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwq......,,.bbvvvvv##.,r,ghg.,.,,,,....,,,,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwq......,.,,bvvvvv###,r,,hgg.,hgh,,,,.,,,,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwq.....#,,,,bvvvvvv##L,r,ghg.,ghgghgg,,,,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..####,.,bbvvvvv##..,r,gg.,.tggggh,,,,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..####,,,.bvvvvvvb..,r,,hm,.ghgggm,,,,,,.,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.####.,,.bbvvvvvbb.#,r,hg,,ggghg,,,,,,,.,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..####,.,.bvvvvvvb.#.,r,.,,gghgh,,,,,,,..qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.###..,..bbvvvvvbb##.r,,.,ghhgm,,,,,,,,.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq....gg,.,.bvvvvvvb..L,r,,,L##h,,,,,,,,L,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq...th.,..bbvvvvvb....,r,,.##.,,,,,,,,g.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqt...gh,R,.bvvvvvbb....,r,,.#.,,,,,,,gggqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq...t.h,,,Lbbv#vvvb...L,r,,...,,.,,,,hg.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.gghgg,.,,bvvvvvbb....,r,,..,,...,,ghmqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..ggg#,,,.bvv#vvvb....,r,,.,,,,,,.mgh.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqtg####,.,bbvvvvvbb...,,r,.,,,,,,,,hg.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..####,..##vv#vvvb....,,r,,,..,,,,gm.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.####.,####vvvvvbb....,r,,...,,,,,..qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..####,####vvvvvvb,,,.,.r,,,,,,L,,L.qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.####,,###bvvvvvb,.....rrr,,,,,,,,,qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.###..,###bvvvvvb.......,rrrrrr,,,..qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..mhgg,,L.bvvvvvbb....,,...rrrrrrrrrrwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqtgtgg...,bbvvvvvb....,,...,......rrrwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..ghgg,...bvvvvvb....,,..,,,.......qwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.tgthT,,,bvvvvvbb..,,,.L,,L......hqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..ghg.,,,bbvvvvvb..,,...,T......mgqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqmh###.,,.bvvvvvbgh,,,,.,,.###..gggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq.#####,..bvvvvvbgm,..L,,,,###.ghgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq#####,,bbvvvvvbg.,,...,..####ggghwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#######,gbvvvvvbh.,,,,,,,.####gghgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww######,gbbvvvvbm,,,,,,L,#####ghhgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww####,,,,gbvvvvb.,,,,,,..#####hgghwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww#...,,.,hbvvvvb.,,,,,,,.#####hgggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqt..,,,gbbvvvb,,,,,,L,######.hggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqqmhghhghbvvvb,,,,,,..#######ggRwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwgthgghgbvvvb,,,,,,,.#######ghgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwgghgtgtbvvvb,,,,,L,.#######hhgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwtghgggbvvvb,,,,,..########mgqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwgggghgbvvvb,,,,,,.########.gqwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwtgththbvvbb,,,,L,.########.gggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwghhghbvvb,,,,,.,.########..hgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwhgghgbvvb,,,,.,..########..ghwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwgggtb=bb,,,,L,..########.mghwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwhggbbvb.,,,,..,.#####gg...hgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwghbvvb.,,,.,.#####ghggh..ggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwRbvvb,,,,L,,###.ghghhgh..gwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwvbb,,,,.,,..##hh.hgtgg.ggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqqqq..,...##.hgggghghhwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqq....###gghghtghgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqq..####gg.gghggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..###gghgtgghwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwqq...hhghggggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq...gggt.mghwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..gggh.#hgwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..ghhg#ggwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
			"wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwq..ggh##gwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
		],
		"sorties": {"1": ["darse", 67, 60]},
		## Alternants sauvages qui se baladent. Cles optionnelles :
		## "case" (depart fixe, sinon une case libre au hasard), "rayon"
		## (distance max a sa case de depart, sinon aucune limite) et "gone"
		## (sa fiche dans data/gones, sinon un sauvage au hasard).
		"pnj": [
			{"nom": "Thomasu", "frames": "res://assets/characters/pnj_thomas/pnj_thomas_frames.tres", "gone": &"thomasu"},
			{"nom": "Guignome", "frames": "res://assets/characters/pnj_guillaume/pnj_guillaume_frames.tres", "gone": &"guignome"},
		],
	},
}

## Variante de sol a poser sur une case. Le tirage depend des coordonnees,
## donc il ne change pas d'une repeinte a l'autre.
## Rails poses a l'horizontale : la tuile de base est verticale.
const RAILS_HORIZONTAUX := {
	"r": Vector2i(7, 6),    # tram
	"v": Vector2i(0, 7),    # train
	"=": Vector2i(1, 7),    # passage a niveau
}

## Sol d'une case dans sa zone : comme sol_de(), mais les rails prennent le sens de
## leurs voisins (horizontaux si la voie continue a gauche ou a droite seulement).
static func sol_de_zone(id: StringName, c: String, cellule: Vector2i) -> Array:
	if RAILS_HORIZONTAUX.has(c):
		var voie := "r" if c == "r" else "v="
		var cote := voie.contains(case_a(id, cellule + Vector2i.LEFT)) \
			or voie.contains(case_a(id, cellule + Vector2i.RIGHT))
		var dessus := voie.contains(case_a(id, cellule + Vector2i.UP)) \
			or voie.contains(case_a(id, cellule + Vector2i.DOWN))
		if cote and not dessus:
			return [TUILES, RAILS_HORIZONTAUX[c]]
	return sol_de(c, cellule)

static func sol_de(c: String, cellule: Vector2i) -> Array:
	if not VARIANTES.has(c):
		return SOLS.get(c, [0, Vector2i(0, 0)])
	var choix: Array = VARIANTES[c]
	var melange := (cellule.x * 73856093) ^ (cellule.y * 19349663)
	return [SOLS[c][0], choix[absi(melange) % choix.size()]]

## Tuile d'un bloc de batiment : facade s'il n'y a pas de "#" en dessous, toit sinon,
## avec un bord a gauche ou a droite quand le batiment s'arrete de ce cote.
static func decor_batiment(id: StringName, cellule: Vector2i) -> Array:
	var gauche := case_a(id, cellule + Vector2i.LEFT) == "#"
	var droite := case_a(id, cellule + Vector2i.RIGHT) == "#"
	if case_a(id, cellule + Vector2i.DOWN) != "#":
		if not gauche:
			return [TUILES, FACADE_GAUCHE]
		if not droite:
			return [TUILES, FACADE_DROITE]
		var melange := (cellule.x * 73856093) ^ (cellule.y * 19349663)
		return [TUILES, FACADES[absi(melange) % FACADES.size()]]
	if not gauche:
		return [TUILES, TOIT_GAUCHE]
	if not droite:
		return [TUILES, TOIT_DROITE]
	return [TUILES, TOIT]

## Bord superieur du toit, pose sur la case au-dessus du rang du haut d'un batiment.
static func haut_batiment(id: StringName, cellule_toit: Vector2i) -> Array:
	if case_a(id, cellule_toit + Vector2i.LEFT) != "#":
		return [TUILES, TOIT_HAUT_GAUCHE]
	if case_a(id, cellule_toit + Vector2i.RIGHT) != "#":
		return [TUILES, TOIT_HAUT_DROITE]
	return [TUILES, TOIT_HAUT]

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
