extends Control
## Le prologue, sur un quai de la gare de Perrache.
##
## Il sert autant a poser l'histoire qu'a dire au joueur ou aller : sans lui,
## on arrive dans une zone sans herbe haute et on croit le jeu casse.
## Texte de reference : docs/histoire.md, section 7.

## Les repliques, dans l'ordre. Un locuteur vide est une narration.
const PROLOGUE: Array[Array] = [
	["", "Le TGV en provenance de Paris entre en gare."],
	["GÉRARD", "Bienvenue à Lyon, Monsieur le Président. Les bureaux de Confluence sont prêts. Il ne manque plus qu'une chose…"],
	["VOUS", "Des employés."],
	["GÉRARD", "Des employés, oui. Et le budget RH est de… zéro euro."],
	["VOUS", "Parfait. Alors on prend des alternants."],
	["", "Au bout du quai, une deuxième portière s'ouvre."],
	["LE RIVAL", "Tiens, tiens… Toi aussi, tu installes ton siège à Confluence ? Les meilleurs alternants de Lyon seront pour MOI. Et surtout ceux de l'EEMI."],
	["VOUS", "L'EEMI ?"],
	["LE RIVAL", "Deuxième étage du Monolithe. Mais le Directeur ne les laisse partir qu'aux patrons qui ont franchi les étages. Bonne chance, « boss »."],
	["GÉRARD", "Il a raison sur un point : il vous faut une équipe. Voici cinq Contrats Basiques, et un premier alternant."],
	["GÉRARD", "Pour aller à Confluence, descendez le Cours Charlemagne vers le sud. Et Monsieur… essayez d'être gentil avec eux. Les alternants, ça parle entre eux."],
]

@onready var _fond: ColorRect = %Fond
@onready var _titre: Label = %Titre
@onready var _sous_titre: Label = %SousTitre
@onready var _boite: BoiteDialogue = %Boite

func _ready() -> void:
	_fond.color = PaletteUi.FOND
	_titre.add_theme_color_override("font_color", PaletteUi.ACCENT)
	_sous_titre.add_theme_color_override("font_color", PaletteUi.TEXTE_DOUX)
	# La partie demarre avant le dialogue : Gerard remet reellement de quoi
	# commencer, et le joueur arrive sur la carte sans ecran de chargement.
	GameState.nouvelle_partie()
	await _jouer_prologue()
	get_tree().change_scene_to_file(GameState.SCENE_MONDE)

func _jouer_prologue() -> void:
	for replique: Array in PROLOGUE:
		await _boite.afficher(replique[1], replique[0])
