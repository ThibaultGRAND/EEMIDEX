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

## Carte du monde (scenes/ui/carte_monde.gd) : une couleur par caractère des plans
## de zones.gd. Un caractère absent prend CARTE_DEFAUT.
const CARTE_DEFAUT := Color("8f8a80")
const COULEURS_CARTE := {
	"#": Color("b5482b"),   # bâtiment (toit)
	".": Color("8f8a80"), ",": Color("a39d90"), "m": Color("7f8a6a"),
	"q": Color("c4bba7"), "d": Color("8a6a45"), "s": Color("d8c48e"),
	"p": Color("9a6b3e"), "w": Color("2f6f9f"),
	"h": Color("5d9a3c"), "t": Color("2f6b2a"), "j": Color("3b7d31"),
	"g": Color("3f7a2b"),   # herbe haute : rencontres
	"b": Color("6b6660"), "v": Color("4a4a4e"), "=": Color("4a4a4e"),
	"r": Color("c9a24a"),   # rails de tram
	"L": Color("8f8a80"), "n": Color("8f8a80"),
}
## Repères dessinés par-dessus la carte : caractère -> couleur du point.
const REPERES_CARTE := {
	"S": Color("2fa84f"),   # soin
	"B": Color("2e86c1"),   # boutique
	"M": Color("9b59b6"),   # entraînement
	"T": Color("b8c2d0"),   # passage sous les voies
	"X": Color("e9c56b"),   # combat final
	"R": Color("d64f8a"),   # ressource
	"1": Color("f4f1ea"), "2": Color("f4f1ea"), "3": Color("f4f1ea"),   # sorties
}
## Le point « vous êtes ici ».
const CARTE_JOUEUR := Color("ff4d4d")
