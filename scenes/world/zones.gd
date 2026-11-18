class_name Zones
extends RefCounted
## Les 4 zones du MVP, decrites en texte. Une ligne = une rangee de cases.
## world.gd construit les TileMapLayer a partir de ces plans.
##
## Une seule carte de la Confluence, generee depuis OpenStreetMap par
## tools/osm_vers_zones.py : de la gare de Perrache a la rue Paul-Montrochet, la
## Saone a gauche, le Rhone a droite. Carte simplifiee : 16 m par case, rues
## principales, ilots pleins, une seule voie ferree. Tournee de 31 degres pour que
## le quadrillage des rues tombe droit. Coupee en 4 bandes collees (ORDRE) :
## Perrache, Sainte-Blandine, Charlemagne (l'EEMI, combat final) et la Darse
## (Montrochet). Les ids des zones n'ont pas change.
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

## Tous les plans font LARGEUR caracteres de large ; la hauteur varie d'une zone a
## l'autre, la camera suit le joueur et se borne sur taille_pixels().
const LARGEUR := 60
const TAILLE_CASE := 16

## Les zones sont des bandes d'une seule carte, collees du nord au sud : on passe de
## l'une a l'autre en sortant par le haut ou par le bas, sur la meme colonne.
## La carte du monde (carte_monde.gd) les dessine dans cet ordre, sans ecart.
const ORDRE: Array[StringName] = [&"perrache", &"sainte_blandine", &"darse", &"pointe"]

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
		"titre": "Perrache — la gare et le cours de Verdun",
		"ressource": &"praline",
		## Boucle de GameState.BOUCLES jouee sous la musique. Les zones sans
		## "ambiance" sont silencieuses.
		"ambiance": &"ambiance_gare",
		"tuile_ressource": Vector2i(3, 13),
		## Pas d'herbe haute a Perrache : on ne croise rien sur le parvis.
		"rencontres": [&"thigoat", &"seb", &"thibouclier"],
		"niveau_min": 3,
		"niveau_max": 5,
		"depart": Vector2i(36, 11),
		"plan": [
			"wwwwwwwwwwwwwwwq###,######,####,,##qwq###,,..,,r,,,,,,,,qwww",
			"wwwwwwwwwwwwwwq.###,,#####,####,,##qwq#,,,,r,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwwq.#,,,,,,,,,,,,,,,,##qwq##gh,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwwwq,,,,,,,,,,,,,,hght#.q.gghg,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwwwq,,,,,,,,,,,,,,hghR####gghg,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwwwq,,,,,,,,,,,,,,thgg####hht,,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwwwq,,,,,,,,,,,,,,,g,,######,,,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwwwq,,,,,,,,,,,,,,,,,,######,,,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwwq,,,,,,,,,,,,,,,,,,,######,,,####,,###,,,,qwww",
			"wwwwwwwwwwwwwwq,,,,,,,,,,,,,,,,,,,######,,,####,,####,,,qwww",
			"wwwwwwwwwwwwwwq,,,,,,,,,,,,,#,,,,#######,,,#####,####,,,qwww",
			"wwwwwwwwwwwwwqR,,,,###########,,,S,T,,B,,,,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwb,,b,bbbbbbbbbbbbb,bb,,,,bbbbbbbbbb,bbbb,,,qwww",
			"wwwwwwwwwwwwwv==v=vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv====www",
			"wwwwwwwwwwwwwb,bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,,,qwww",
			"wwwwwwwwwwwwvv=vv=vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv====www",
			"wwwwwwwwwwwwbb,bb,bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb,,,qwww",
			"wwwwwwwwwwwwv==vv=vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv=vvvv====www",
			"wwwwwwwwwwwbb,,bb,bbbbbbbbbbbbbbbbb,r,bbbbbbbbb,,bbbb,,,qwww",
			"wwwwwwwwwwwvv==vv=vvvvvvvvvvv=vvvvv=v=vvv==vvvv==vvvv====www",
			"wwwwwwwwwwwbb,bbb,bbbbbbbbbbb,bbbbb,r,bbb,,bbbbb,bbbb,,,qwww",
			"wwwwwwwwwwq.#,###,#ggth#####g,###..Tr,,,,,,#####,####,,,qwww",
			"wwwwwwwwwwq#,,###,#########tg,####.,r,...,,#####,####,,,qwww",
		],
		"sorties": {},
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
		"titre": "Sainte-Blandine — Charlemagne et Casimir-Périer",
		"ressource": &"cocon",
		"tuile_ressource": Vector2i(4, 13),
		"rencontres": [&"roulian", &"matiti", &"e1000"],
		"niveau_min": 4,
		"niveau_max": 7,
		"depart": Vector2i(29, 11),
		"plan": [
			"wwwwwwwwwwq#,,###,.ghggt###gh,#####,r,####,#####,####,,,qwww",
			"wwwwwwwwwwq#,####,.tgggg####g,#####,r,####,#####,#####,,qwww",
			"wwwwwwwwwq.,,####,##########g,#####,r,####,#####,#####,,qwww",
			"wwwwwwwwwq#,,####,###########,#####,r,####,#####,#####,,qwww",
			"wwwwwwwwwq#,,,###,,,,#,,,#,,#,,#,#,,r,,,#,,#,,#,,####,,,qwww",
			"wwwwwwwwwq#,,,,,,,,,,,,,,,,,,,,,,,,,r,,,,,,,,,,,,,,,,,,,qwww",
			"wwwwwwwwq.,,#####,#####,,####,##,##,r,####,#,,##,#####,,qwww",
			"wwwwwwwwq#,,#####,#####,,####,##,##,r,####,##,##,#####,,qwww",
			"wwwwwwwwq#,,#####,#####,,####,##,##,r,####,##,##,#####,,qwww",
			"wwwwwwwwq#,######,#####,,####,##,##,r,####,##,##,#####,,qwww",
			"wwwwwwwq.#,######,#####,,####,##,##,r,####,##,##,#####,,qwww",
			"wwwwwwwq#,,######,#####,,####,##,##,r,####,##,##,#####,,qwww",
			"wwwwwwwq#,,######,#####,,####,##,#M,r,,,,,,,,,,,,,,,,,,,qwww",
			"wwwwwwwq#,,,,,,,,,,,,,,,,,,,,,,,,,,,r,,,,,,,,,,,,,,,,,,,qwww",
			"wwwwwwwq#,,############,,#######,##,r,g###,##,##,#####,,qwww",
			"wwwwwwq##,,############,########,##,r,t###,##,##,#####,,qwww",
			"wwwwwwq##,,.hg#########,########,##,r,gg##,##,##,#####,,qwww",
			"wwwwwwq##,,#gh#########,########,##,r,####,##,##,#####,,qwww",
			"wwwwwwqhg,,#gg#########,,#######,##,r,hg##,##,##,#####,,qwww",
			"wwwwwwqth,,#tg#########,,ght####,##,r,gg##,##,##,#####,,qwww",
			"wwwwwqhgh,,#gR#########,hRhgg###,##,r,tRg#,#,,##,#####,,qwww",
			"wwwwwqghg,,#hg#########,,hgg####,,,,r,,,,,,,,,,,,,,,,,,,qwww",
			"wwwwwqggg,,############,,#######,##,r,####,##,##,#####,,qwww",
		],
		"sorties": {},
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
		"titre": "Charlemagne — la patinoire et l'EEMI",
		"ressource": &"quenelle",
		"tuile_ressource": Vector2i(5, 13),
		"rencontres": [&"palou", &"tortheo", &"cecissoussou"],
		"niveau_min": 7,
		"niveau_max": 10,
		"depart": Vector2i(32, 11),
		"plan": [
			"wwwwwqthg,,############,,#######,##,r,####,##,##,##t##,,qwww",
			"wwwwwqh##,,############,########,##,r,####,##,##,#gg##,,qwww",
			"wwwwwqh##,,#########ghg,########,##,r,####,##,##,hRg##,,qwww",
			"wwwwwq###,,#########ggh,########,##,r,####,##,##,thhg#,,qwww",
			"wwwwwq###,,############,########,##,r,####,##,##,#hg##,,qwww",
			"wwwwwq###,,###########g,,#######,##,r,####,##,##,#####,,qwww",
			"wwwwwq###,,,,,,,,,,,,,,,,,,,,,,,,,,,r,,,,,,,,,,,,,,,,,,,qwww",
			"wwwwwq#########,,######,,######,,##,r,###,,#,,##,#####,,qwww",
			"wwwwwq##########,gg#gh#,,#######,##,r,####,##,##,#####,,qwww",
			"wwwwwq.#########,hg#tgh,,#######,##,r,####,##,##,#####,,qwww",
			"wwwwwwq#########,#g#ggh,,#######,##,r,####,##,##,#####,,qwww",
			"wwwwwwq#########,#h#hht,,#######,##,r,####,##,##,#####,,qwww",
			"wwwwwwq#########,#t##g#,,#######,##,r,####,##,##,#####,,qwww",
			"wwwwwwq#########,######,,#######,##,r,####,##,##,#####,,qwww",
			"wwwwwwq#########,######,,##,,,#,,,,,r,###,,#,,#,,#####,,qwww",
			"wwwwwwq##qqq,,,,,,,,,,,,,,,,,,,,,,,,r,,,,,,,,,,,,,,,,,,,qwww",
			"wwwwwwqtqwwwq####t#####,,##########,r,####,####,,..###,,qwww",
			"wwwwwwqgqwwwq####g#####,,##########,r,####,####,,#####,,qwww",
			"wwwwwq.RqwwwqgthghhthX#,,##########,r,ht##,####,,#####,,qwww",
			"wwwwwwqghqwwqggghggRgg#,,##########,r,g###,ghtg,,#####,,qwww",
			"wwwwwwqgqwwwqhggtggggt#,,##########,r,g###,####,,#gth#,,qwww",
			"wwwwwwqtqwwwqghhghgggg#,,##########,r,g###,####,,ghhg#,,qwww",
			"wwwwwwqgqwwwq####gt####,,##########,r,t###,tghg,,###gt,,qwww",
		],
		"sorties": {},
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
		"titre": "La Darse — Montrochet et l'Hôtel de Région",
		"ressource": &"cocon",
		"tuile_ressource": Vector2i(4, 13),
		"rencontres": [&"thomasu", &"paguera", &"guignome"],
		"niveau_min": 10,
		"niveau_max": 13,
		"depart": Vector2i(35, 11),
		"plan": [
			"wwwwwwq.qwwwq##########,,##########,r,####,####,,#ghgh,,qwww",
			"wwwwwwwq#qqq,##########,,,,,,,,,,,,,r,....,,,,,,,#####,,qwww",
			"wwwwwwwq###.qqqqqqqqqqqqqqqqqqqqqq,,r,....,,,,,,,#####,,qwww",
			"wwwwwwwq###qwwwwwwwwwwwwwwwwwwwwwwq,r,L..L,####,,#####,,qwww",
			"wwwwwwwwq#.qwwwwwwwwwwwwwwwwwwwwwwq,r,.R..,####,,#####,,qwww",
			"wwwwwwwwqqqwwwwwwwwwwwwwwwwwwwwwwq.,r,....,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwwwwwwwwwwwqqqqqqqqqq..,r,####,###########,,qwww",
			"wwwwwwwwwwwwwqqqqqqqqqq.###########,r,####,###########,,qwww",
			"wwwwwwwwwqqqwwwwq##################,r,####,###########,,qwww",
			"wwwwwwwwwwqgqwwwq##################,r,####,###########,,qwww",
			"wwwwwwwwwwqRhqwwq##################,r,####,###########,,qwww",
			"wwwwwwwwwwqmgqwwq##################,r,####,###########,,qwww",
			"wwwwwwwwwwwqgqwwq##################,r,####,###########,,qwww",
			"wwwwwwwwwwwq..qwq##################,r,####,###########,,qwww",
			"wwwwwwwwwwwwq#.q###################,r,####,###########,,qwww",
			"wwwwwwwwwwwwq##qq,,,,,,,,,,,,,,,,,,,r,,,,,,,,,,,,,,,,,,,qwww",
			"wwwwwwwwwwwwwqqwwq,####,,##########,r,,,#,,,,##,,,###,,,qwww",
			"wwwwwwwwwwwwwqgqwwq####,,##########,r,#########g######,,qwww",
			"wwwwwwwwwwwwwqmhqwqq###,,##########,r,#########g######,,qwww",
			"wwwwwwwwwwwwwwqqwwwwq##,,##########,r,#########h######,,qwww",
			"wwwwwwwwwwwwwwwqqwwwq..,,,,,,,,,,,,,r,#########R######,,qwww",
			"wwwwwwwwwwwwwwwq.qwwq..,,,,,,,,,,,,,r,#########g######,,qwww",
			"wwwwwwwwwwwwwwwwq.qq...,,##########,r,#########h######,,qwww",
		],
		"sorties": {},
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

## La bande voisine au nord (sens = -1) ou au sud (sens = 1), ou &"" au bord du monde.
static func zone_voisine(id: StringName, sens: int) -> StringName:
	var i := ORDRE.find(id) + sens
	if i < 0 or i >= ORDRE.size() or ORDRE.find(id) < 0:
		return &""
	return ORDRE[i]

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
