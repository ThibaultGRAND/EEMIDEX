class_name FicheCombattant
extends PanelContainer
## L'étiquette d'un alternant en combat : son nom, son niveau, son type, sa
## Motivation et son Café.
##
## Elle ne connaît pas les règles : le combat lui donne des nombres, elle les
## affiche. `depuis_gone()` est juste un raccourci qui lit un GoneInstance.
##
## Usage :
##   %FicheJoueur.depuis_gone(actif)
##   await %FicheJoueur.definir_motivation(actif.pv, actif.pv_max())

## Les chiffres « 18/24 » sous la jauge. On les cache pour l'adversaire, comme
## dans les Pokémon : on voit la jauge baisser, pas le compte exact.
@export var montrer_chiffres: bool = true:
	set(valeur):
		montrer_chiffres = valeur
		if is_node_ready():
			_chiffres.visible = valeur

## Le Café n'est pas encore implémenté côté combat : la ligne reste cachée
## tant qu'on ne lui donne pas de valeur.
@export var montrer_cafe: bool = false:
	set(valeur):
		montrer_cafe = valeur
		if is_node_ready():
			_ligne_cafe.visible = valeur

@onready var _nom: Label = %Nom
@onready var _niveau: Label = %Niveau
@onready var _badge: BadgeType = %Badge
@onready var _motivation: BarreJauge = %Motivation
@onready var _chiffres: Label = %Chiffres
@onready var _ligne_cafe: HBoxContainer = %LigneCafe
@onready var _cafe: BarreJauge = %Cafe

func _ready() -> void:
	_chiffres.visible = montrer_chiffres
	_ligne_cafe.visible = montrer_cafe
	_cafe.couleur_fixe = PaletteUi.JAUGE_CAFE

## L'identité du combattant : ce qui ne bouge pas pendant son tour.
func definir_combattant(nom: String, niveau: int, type: StringName) -> void:
	_nom.text = nom
	_niveau.text = "Niv.%d" % niveau
	_badge.definir(type)

## Pose la Motivation. À attendre (`await`) pour laisser la jauge descendre
## avant la ligne de texte suivante.
func definir_motivation(valeur: int, maximum: int, anime: bool = true) -> Signal:
	_motivation.definir(valeur, maximum, anime)
	_chiffres.text = "%d/%d" % [valeur, maximum]
	return _motivation.animation_terminee

## Pose le Café. Affiche la ligne au passage.
func definir_cafe(valeur: int, maximum: int, anime: bool = true) -> Signal:
	montrer_cafe = true
	_cafe.definir(valeur, maximum, anime)
	return _cafe.animation_terminee

## Raccourci : remplit la fiche à partir d'un GoneInstance.
func depuis_gone(gone: Object, anime: bool = false) -> void:
	if gone == null:
		return
	var type: StringName = &"neutre"
	if gone.get("data") != null:
		type = gone.data.type
	definir_combattant(gone.nom(), gone.niveau, type)
	definir_motivation(gone.pv, gone.pv_max(), anime)
