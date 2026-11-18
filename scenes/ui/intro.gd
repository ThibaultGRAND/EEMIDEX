extends Control
## Le prologue, sur un quai de la gare de Perrache.
##
## Le joueur choisit d'abord son patron, puis la scene se joue. Elle sert
## autant a poser l'histoire qu'a dire ou aller : sans elle, on arrive dans
## une zone sans herbe haute et on croit le jeu casse.
## Texte de reference : docs/histoire.md, sections 2 et 7.

@onready var _fond: ColorRect = %Fond
@onready var _titre: Label = %Titre
@onready var _boite: BoiteDialogue = %Boite
@onready var _menu: ListeMenu = %Menu
@onready var _portraits: Control = %Portraits
@onready var _portrait_a: TextureRect = %PortraitA
@onready var _portrait_b: TextureRect = %PortraitB
@onready var _nom_a: Label = %NomA
@onready var _nom_b: Label = %NomB

func _ready() -> void:
	_fond.color = PaletteUi.FOND
	_titre.add_theme_color_override("font_color", PaletteUi.ACCENT)
	await _choisir_le_heros()
	# La partie demarre apres le choix : nouvelle_partie() lit le heros pour
	# en tirer les bonus, et remet contrats et premier alternant.
	GameState.nouvelle_partie()
	await _jouer_prologue()
	get_tree().change_scene_to_file(GameState.SCENE_MONDE)

## Deux patrons, deux bonus. Celui qu'on laisse devient le rival.
func _choisir_le_heros() -> void:
	_titre.text = "Deux silhouettes descendent du TGV"
	var identifiants: Array = GameState.HEROS.keys()
	_poser_portrait(_portrait_a, _nom_a, identifiants[0])
	_poser_portrait(_portrait_b, _nom_b, identifiants[1])
	var options: Array = []
	for identifiant: StringName in GameState.HEROS:
		var fiche: Dictionary = GameState.HEROS[identifiant]
		options.append({
			"id": identifiant,
			"texte": str(fiche["nom"]),
			"detail": str(fiche["bonus"]),
		})
	_menu.definir_options(options)
	_menu.visible = true
	_boite.afficher_invite("Flèches pour comparer, Entrée pour signer.")
	_menu.choix_change.connect(_sur_survol)
	_sur_survol(0, options[0]["id"])
	var choix: Array = await _menu.choix_valide
	GameState.heros = StringName(choix[1])
	_menu.visible = false
	_portraits.visible = false

## Le curseur fait parler le patron survole : on choisit sur une replique,
## pas sur une ligne de statistiques.
func _sur_survol(_index: int, identifiant: StringName) -> void:
	var fiche: Dictionary = GameState.HEROS[identifiant]
	_boite.afficher_invite(str(fiche["replique"]), str(fiche["nom"]).to_upper())
	# Le patron survole ressort, l'autre s'efface : on voit qui on choisit.
	var identifiants: Array = GameState.HEROS.keys()
	_eclairer(_portrait_a, _nom_a, identifiants[0] == identifiant)
	_eclairer(_portrait_b, _nom_b, identifiants[1] == identifiant)

## Pose l'image fixe du patron, de face, et son nom.
func _poser_portrait(portrait: TextureRect, nom: Label, identifiant: StringName) -> void:
	var fiche: Dictionary = GameState.HEROS[identifiant]
	nom.text = str(fiche["nom"])
	var planche: SpriteFrames = load(str(fiche["frames"]))
	if planche != null and planche.has_animation(&"idle_down"):
		portrait.texture = planche.get_frame_texture(&"idle_down", 0)
	portrait.modulate = fiche["teinte"]
	portrait.set_meta("teinte", fiche["teinte"])

## Le choisi garde sa teinte, l'autre est assombri.
func _eclairer(portrait: TextureRect, nom: Label, choisi: bool) -> void:
	var teinte: Color = portrait.get_meta("teinte", Color.WHITE)
	portrait.modulate = teinte if choisi else PaletteUi.assombrir(teinte, 0.4)
	nom.add_theme_color_override("font_color",
		PaletteUi.ACCENT if choisi else PaletteUi.TEXTE_ETEINT)

func _jouer_prologue() -> void:
	_titre.text = "Gare de Perrache — quai B, 8 h 12"
	# La premiere replique annonce le TGV : on l'entend entrer. L'ambiance de
	# la gare demarre ici et continue sans coupure sur la carte.
	GameState.jouer_ambiance(&"ambiance_gare")
	GameState.jouer_son(&"train_en_gare", -10.0)
	for replique: Array in _repliques():
		await _boite.afficher(replique[1], replique[0])

## Les repliques, dans l'ordre. Un locuteur vide est une narration.
## Le titre et le nom du rival dependent du patron choisi.
func _repliques() -> Array:
	var moi: Dictionary = GameState.fiche_heros()
	var autre: Dictionary = GameState.fiche_rival()
	return [
		["", "Le TGV en provenance de Paris entre en gare."],
		["GÉRARD", "Bienvenue à Lyon, %s. Les bureaux de Confluence sont prêts. Il ne manque plus qu'une chose…" % moi["titre"]],
		[str(moi["nom"]).to_upper(), "Des employés."],
		["GÉRARD", "Des employés, oui. Et le budget RH est de… zéro euro."],
		[str(moi["nom"]).to_upper(), "Parfait. Alors on prend des alternants."],
		["", "Au bout du quai, une deuxième portière s'ouvre. %s en descend." % autre["nom"]],
		[str(autre["nom"]).to_upper(), "Tiens, tiens… Toi aussi, tu installes ton siège à Confluence ? Les meilleurs alternants de Lyon seront pour MOI. Et surtout ceux de l'EEMI."],
		[str(moi["nom"]).to_upper(), "L'EEMI ?"],
		[str(autre["nom"]).to_upper(), "Deuxième étage du Monolithe. Mais le Directeur ne les laisse partir qu'aux patrons qui ont franchi les étages. Bonne chance, « boss »."],
		["GÉRARD", "Il a raison sur un point : il vous faut une équipe. Voici cinq Contrats Basiques, et un premier alternant."],
		["GÉRARD", "Pour aller à Confluence, descendez le Cours Charlemagne vers le sud. Et %s… essayez d'être gentil avec eux. Les alternants, ça parle entre eux." % moi["titre"]],
	]
