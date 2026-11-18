class_name MoveData
extends Resource
## Une attaque ou un pouvoir signature. Un fichier .tres par attaque dans data/moves/.

enum Cible { ADVERSAIRE, SOI }

@export var id: StringName = &""
@export var display_name: String = "Attaque"
@export_multiline var description: String = ""
@export var type: StringName = &"neutre"
@export var cible: Cible = Cible.ADVERSAIRE

@export_group("Dégâts")
## 0 = attaque de soutien (ne fait pas de dégâts).
@export_range(0, 120) var puissance: int = 10
@export_range(0, 100) var precision: int = 95

@export_group("Effets")
## Degats infliges a la fin de chaque tour, et pendant combien de tours.
@export_range(0, 20) var brulure_degats: int = 0
@export_range(0, 5) var brulure_tours: int = 0
## L'adversaire passe son tour suivant.
@export var etourdit: bool = false
## Degats tires au hasard entre ces deux bornes, au lieu de la puissance.
@export_range(0, 60) var degats_min: int = 0
@export_range(0, 60) var degats_max: int = 0
## Ce que l'attaque coute en Motivation a celui qui la lance.
@export_range(0, 20) var cout_pv: int = 0
## Chance, en pourcentage, de frapper une fois et demie plus fort.
@export_range(0, 100) var chance_critique: int = 0
## Tours d'attente avant de pouvoir la relancer. 0 = utilisable a volonte.
@export_range(0, 6) var recharge: int = 0

@export_group("Effet de soutien")
## "attaque", "defense" ou "vitesse". Vide = pas de bonus.
@export var stat_modifiee: StringName = &""
@export_range(-5, 5) var modificateur: int = 0
## Points de vie rendus à l'utilisateur.
@export_range(0, 50) var soin: int = 0

## Le Cafe que coute cette attaque. Voir docs/regles.md.
## Une attaque de soutien coute le minimum ; sinon un cinquieme de sa puissance,
## arrondi au superieur. "Trainer des pieds" est la seule attaque gratuite.
func cout_cafe() -> int:
	if id == &"trainer_des_pieds":
		return 0
	return maxi(2, int(ceil(puissance / 5.0)))
