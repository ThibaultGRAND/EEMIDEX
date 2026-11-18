class_name GoneInstance
extends RefCounted
## Un Gone tel qu'il existe pendant la partie : sa fiche (GoneData) plus
## son niveau, ses PV du moment et les bonus gagnés dans les mini-jeux.

var data: GoneData
var niveau: int = 5
var pv: int = 0
var cafe: int = 0
var bonus_pv: int = 0
var bonus_attaque: int = 0
var bonus_defense: int = 0
var bonus_vitesse: int = 0

func _init(p_data: GoneData = null, p_niveau: int = 5) -> void:
	data = p_data
	niveau = p_niveau
	pv = pv_max()
	cafe = cafe_max()

func nom() -> String:
	return data.display_name if data != null else "???"

func pv_max() -> int:
	if data == null:
		return 1
	return data.base_pv + bonus_pv + (niveau - 1) * 2

## L'energie disponible pour attaquer.
func cafe_max() -> int:
	return 20 + (niveau - 1) * 2

func depenser_cafe(montant: int) -> void:
	cafe = maxi(0, cafe - montant)

func recuperer_cafe(montant: int) -> void:
	cafe = mini(cafe_max(), cafe + montant)

func cafe_plein() -> void:
	cafe = cafe_max()

## Peut-il se payer cette attaque ?
func peut_lancer(attaque: MoveData) -> bool:
	return attaque != null and cafe >= attaque.cout_cafe()

func attaque() -> int:
	if data == null:
		return 1
	return data.base_attaque + bonus_attaque + (niveau - 1)

func defense() -> int:
	if data == null:
		return 1
	return data.base_defense + bonus_defense + (niveau - 1)

func vitesse() -> int:
	if data == null:
		return 1
	return data.base_vitesse + bonus_vitesse + (niveau - 1)

func est_ko() -> bool:
	return pv <= 0

func soigner(montant: int) -> void:
	pv = clampi(pv + montant, 0, pv_max())

func subir(montant: int) -> void:
	pv = clampi(pv - montant, 0, pv_max())

func soigner_tout() -> void:
	pv = pv_max()
	cafe = cafe_max()

## Les attaques disponibles en combat : l'attaque de base, puis le pouvoir.
func attaques() -> Array:
	var liste: Array = []
	if data == null:
		return liste
	if data.attaque_de_base != null:
		liste.append(data.attaque_de_base)
	if data.pouvoir_signature != null:
		liste.append(data.pouvoir_signature)
	return liste

## Applique le score d'un mini-jeu à une stat. Renvoie le gain réellement accordé.
func appliquer_entrainement(stat: StringName, gain: int) -> int:
	match stat:
		&"pv":
			bonus_pv += gain
			pv += gain
		&"attaque":
			bonus_attaque += gain
		&"defense":
			bonus_defense += gain
		&"vitesse":
			bonus_vitesse += gain
		_:
			return 0
	return gain

func to_dict() -> Dictionary:
	return {
		"gone_id": String(data.id) if data != null else "",
		"niveau": niveau,
		"pv": pv,
		"cafe": cafe,
		"bonus_pv": bonus_pv,
		"bonus_attaque": bonus_attaque,
		"bonus_defense": bonus_defense,
		"bonus_vitesse": bonus_vitesse,
	}

static func from_dict(d: Dictionary, catalogue: Dictionary) -> GoneInstance:
	var fiche: GoneData = catalogue.get(StringName(d.get("gone_id", "")))
	var g := GoneInstance.new(fiche, int(d.get("niveau", 5)))
	g.bonus_pv = int(d.get("bonus_pv", 0))
	g.bonus_attaque = int(d.get("bonus_attaque", 0))
	g.bonus_defense = int(d.get("bonus_defense", 0))
	g.bonus_vitesse = int(d.get("bonus_vitesse", 0))
	g.pv = clampi(int(d.get("pv", g.pv_max())), 0, g.pv_max())
	g.cafe = clampi(int(d.get("cafe", g.cafe_max())), 0, g.cafe_max())
	return g
