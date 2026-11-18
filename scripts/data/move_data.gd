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
