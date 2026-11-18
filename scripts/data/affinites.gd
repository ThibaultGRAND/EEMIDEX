class_name Affinites
extends RefCounted
## Les six types d'alternants, en cycle ferme : chacun bat le suivant et perd
## contre le precedent. Voir docs/histoire.md.
##
##   Dev -> Data -> Product -> Com -> Marketing -> Design -> Dev
##
## Un type absent du cycle (&"neutre", ou un type pas encore decide) ne donne
## ni avantage ni desavantage : le multiplicateur vaut 1.

const CYCLE: Array[StringName] = [
	&"dev", &"data", &"product", &"com", &"marketing", &"design",
]

const TRES_EFFICACE := 2.0
const PEU_EFFICACE := 0.5
const NORMAL := 1.0

## Combien l'attaque fait de degats contre cette cible.
static func multiplicateur(type_attaque: StringName, type_cible: StringName) -> float:
	var attaquant := CYCLE.find(type_attaque)
	var cible := CYCLE.find(type_cible)
	if attaquant < 0 or cible < 0:
		return NORMAL
	if CYCLE[(attaquant + 1) % CYCLE.size()] == type_cible:
		return TRES_EFFICACE
	if CYCLE[(cible + 1) % CYCLE.size()] == type_attaque:
		return PEU_EFFICACE
	return NORMAL

## Ce que le combat annonce au joueur. Vide quand il n'y a rien a dire.
static func commentaire(valeur: float) -> String:
	if valeur > NORMAL:
		return "C'est très efficace !"
	if valeur < NORMAL:
		return "Ce n'est pas très efficace..."
	return ""

## Le type que ce type bat, pour l'affichage d'une fiche.
static func bat(type: StringName) -> StringName:
	var i := CYCLE.find(type)
	return CYCLE[(i + 1) % CYCLE.size()] if i >= 0 else &""

## Le type qui bat ce type.
static func battu_par(type: StringName) -> StringName:
	var i := CYCLE.find(type)
	return CYCLE[(i - 1 + CYCLE.size()) % CYCLE.size()] if i >= 0 else &""
