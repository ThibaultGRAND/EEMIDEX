class_name Affinites
extends RefCounted
## Les types d'alternants, en cycle ferme : chacun bat le suivant et perd
## contre le precedent. Voir docs/histoire.md.
##
##   Dev -> Data -> Product -> Marketing -> Design -> Dev
##
## Com et Marketing sont le meme metier : &"com" est un alias de &"marketing".
##
## Les types hors du cycle ne donnent ni avantage ni desavantage, le
## multiplicateur vaut 1 dans les deux sens :
##   &"staff"   l'encadrement de l'ecole, Nael et Tristan. Ce ne sont pas des
##              etudiants, la pierre-feuille-ciseaux des metiers ne s'applique
##              pas a eux : on les bat sur les stats, pas sur le type.
##   &"neutre"  un alternant sans specialite.

const CYCLE: Array[StringName] = [
	&"dev", &"data", &"product", &"marketing", &"design",
]

## Noms differents, meme type.
const ALIAS := {
	&"com": &"marketing",
}

const TRES_EFFICACE := 2.0
const PEU_EFFICACE := 0.5
const NORMAL := 1.0

## Ramene un type ecrit autrement a celui du cycle.
static func canonique(type: StringName) -> StringName:
	return ALIAS.get(type, type)

## Combien l'attaque fait de degats contre cette cible.
static func multiplicateur(type_attaque: StringName, type_cible: StringName) -> float:
	var attaquant := CYCLE.find(canonique(type_attaque))
	var cible := CYCLE.find(canonique(type_cible))
	if attaquant < 0 or cible < 0:
		return NORMAL
	if CYCLE[(attaquant + 1) % CYCLE.size()] == CYCLE[cible]:
		return TRES_EFFICACE
	if CYCLE[(cible + 1) % CYCLE.size()] == CYCLE[attaquant]:
		return PEU_EFFICACE
	return NORMAL

## Ce que le combat annonce au joueur. Vide quand il n'y a rien a dire.
static func commentaire(valeur: float) -> String:
	if valeur > NORMAL:
		return "C'est très efficace !"
	if valeur < NORMAL:
		return "Ce n'est pas très efficace..."
	return ""

## Le type que ce type bat, pour l'affichage d'une fiche. Vide hors du cycle.
static func bat(type: StringName) -> StringName:
	var i := CYCLE.find(canonique(type))
	return CYCLE[(i + 1) % CYCLE.size()] if i >= 0 else &""

## Le type qui bat ce type. Vide hors du cycle.
static func battu_par(type: StringName) -> StringName:
	var i := CYCLE.find(canonique(type))
	return CYCLE[(i - 1 + CYCLE.size()) % CYCLE.size()] if i >= 0 else &""
