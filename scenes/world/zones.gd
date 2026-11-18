class_name Zones
extends RefCounted
## Les 3 zones du MVP, décrites en texte. Une ligne = une rangée de cases.
## Remplacer ce plan par une TileMapLayer quand les tilesets seront dessinés :
## seules les fonctions de world.gd qui lisent `plan` changeront.
##
## Légende :
##   #  mur            .  sol libre        g  herbe / ruelle (rencontres)
##   S  soin           B  boutique         M  salle d'entraînement
##   T  traboule       R  ressource        X  combat de fin
##   1 2 3             sortie vers une autre zone

const LARGEUR := 20
const HAUTEUR := 10
const TAILLE_CASE := 16

const ZONES := {
	&"presquile": {
		"titre": "Presqu'île — Bellecour",
		"sol": Color(0.439216, 0.423529, 0.380392),
		"ressource": &"praline",
		"rencontres": [&"generique_gone", &"generique_quenellon"],
		"niveau_min": 3,
		"niveau_max": 5,
		"plan": [
			"####################",
			"#..................#",
			"#..S............B..#",
			"#..................#",
			"#.......M..........#",
			"#..................#",
			"#...gg.......gg....#",
			"#...gg.......gg....2",
			"#.........R........#",
			"####################",
		],
		"sorties": {"2": ["vieux_lyon", 2, 1]},
	},
	&"vieux_lyon": {
		"titre": "Vieux Lyon — les traboules",
		"sol": Color(0.380392, 0.360784, 0.396078),
		"ressource": &"cocon",
		"rencontres": [&"generique_gone", &"generique_traboulin"],
		"niveau_min": 5,
		"niveau_max": 8,
		"plan": [
			"####################",
			"1..................#",
			"#.gg...###...gg....#",
			"#.gg...#T#...gg....#",
			"#..................#",
			"#.....R......###...#",
			"#............#T#...#",
			"#..gg..............#",
			"#..gg..........R...3",
			"####################",
		],
		"sorties": {"1": ["presquile", 18, 7], "3": ["fourviere", 2, 1]},
	},
	&"fourviere": {
		"titre": "Fourvière — la colline",
		"sol": Color(0.47451, 0.443137, 0.380392),
		"ressource": &"quenelle",
		"rencontres": [&"generique_traboulin", &"generique_quenellon"],
		"niveau_min": 8,
		"niveau_max": 11,
		"plan": [
			"####################",
			"2..................#",
			"#...gg....R....gg..#",
			"#...gg.........gg..#",
			"#..................#",
			"#.........X........#",
			"#..................#",
			"#...gg....R....gg..#",
			"#...gg.........gg..#",
			"####################",
		],
		"sorties": {"2": ["vieux_lyon", 18, 8]},
	},
}

const CASES_BLOQUEES := "#"

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
	return not CASES_BLOQUEES.contains(case_a(id, position))

## Les deux bouts d'une traboule : on sort par l'autre.
static func autre_traboule(id: StringName, depuis: Vector2i) -> Vector2i:
	var plan: Array = zone(id)["plan"]
	for y in plan.size():
		var ligne: String = plan[y]
		for x in ligne.length():
			if ligne[x] == "T" and Vector2i(x, y) != depuis:
				return Vector2i(x, y)
	return depuis
