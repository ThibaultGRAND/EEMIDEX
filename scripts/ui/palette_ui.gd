class_name PaletteUi
extends RefCounted
## Les couleurs de l'interface, au même endroit pour tous les écrans.
##
## Rien d'autre que des constantes et des fonctions statiques : aucun écran ne
## code une couleur en dur, il demande ici. Changer la charte = changer ce
## fichier. Les couleurs des panneaux et du texte sont aussi dans le thème
## `scenes/ui/theme_moustache.tres`, qui s'applique tout seul aux Control.

## Fond des écrans et creux des jauges.
const FOND := Color("10141c")
## Remplissage des panneaux.
const PANNEAU := Color("1b2230")
## Bordure des panneaux et des jauges.
const BORDURE := Color("3c4a60")
## Couleur d'accent : curseur, titres, valeurs importantes.
const ACCENT := Color("e9c56b")
## Texte courant.
const TEXTE := Color("dfe6ef")
## Texte secondaire : légendes, unités, détails.
const TEXTE_DOUX := Color("90a0b4")
## Texte d'une entrée de menu indisponible.
const TEXTE_ETEINT := Color("5a6878")

const JAUGE_HAUTE := Color("6cc24a")
const JAUGE_MOYENNE := Color("e9c56b")
const JAUGE_BASSE := Color("d6584a")
## Jauge de Café (l'énergie des attaques).
const JAUGE_CAFE := Color("b4794a")

## Au-dessus : jauge verte. En dessous de SEUIL_BAS : jauge rouge.
const SEUIL_MOYEN := 0.5
const SEUIL_BAS := 0.2

## Une couleur par type d'alternant. Les alias (&"com") passent par
## Affinites.canonique() avant d'arriver ici.
const COULEURS_TYPE := {
	&"dev": Color("4a8fd6"),
	&"data": Color("6f5bd0"),
	&"product": Color("d68c3a"),
	&"marketing": Color("d64a7a"),
	&"design": Color("45b89a"),
	&"staff": Color("8a93a8"),
	&"neutre": Color("7f8c99"),
}

## Ce qu'on écrit sur le badge d'un type.
const LIBELLES_TYPE := {
	&"dev": "Dev",
	&"data": "Data",
	&"product": "Product",
	&"marketing": "Marketing",
	&"design": "Design",
	&"staff": "Staff",
	&"neutre": "Neutre",
}

## La couleur du badge d'un type. Les types inconnus tombent sur le neutre.
static func couleur_type(type: StringName) -> Color:
	return COULEURS_TYPE.get(Affinites.canonique(type), COULEURS_TYPE[&"neutre"])

## Le texte du badge d'un type. Un type inconnu s'affiche tel qu'il est écrit.
static func libelle_type(type: StringName) -> String:
	var canon: StringName = Affinites.canonique(type)
	return LIBELLES_TYPE.get(canon, String(canon).capitalize())

## La couleur d'une jauge de Motivation selon ce qu'il en reste.
static func couleur_jauge(ratio: float) -> Color:
	if ratio <= SEUIL_BAS:
		return JAUGE_BASSE
	if ratio <= SEUIL_MOYEN:
		return JAUGE_MOYENNE
	return JAUGE_HAUTE

## Une couleur assombrie, pour la bordure d'un élément coloré (badge, jauge).
static func assombrir(couleur: Color, facteur: float = 0.55) -> Color:
	return Color(couleur.r * facteur, couleur.g * facteur, couleur.b * facteur, couleur.a)
