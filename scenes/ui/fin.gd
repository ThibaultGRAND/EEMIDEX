extends Control
## L'epilogue. Laquelle des deux fins depend de la Bienveillance RH, le
## compteur cache que le joueur a fait monter ou descendre sans le voir.
## Texte de reference : docs/histoire.md section 8.

@onready var _fond: ColorRect = %Fond
@onready var _titre: Label = %Titre
@onready var _boite: BoiteDialogue = %Boite

func _ready() -> void:
	_fond.color = PaletteUi.FOND
	var bienveillante := GameState.fin_bienveillante()
	_titre.text = "Un partenariat avec l'EEMI" if bienveillante else "Des bureaux vides"
	_titre.add_theme_color_override("font_color",
		PaletteUi.ACCENT if bienveillante else PaletteUi.JAUGE_BASSE)
	for replique: Array in (_fin_bienveillante() if bienveillante else _fin_exploiteuse()):
		await _boite.afficher(replique[1], replique[0])
	_titre.text = "MOUSTACHE QUEST"
	await _boite.afficher("Merci d'avoir joué.", "")
	get_tree().change_scene_to_file(GameState.SCENE_MENU)

func _fin_bienveillante() -> Array:
	var moi: Dictionary = GameState.fiche_heros()
	return [
		["", "Avant le dernier coup, votre équipe s'avance devant le Directeur."],
		["VOTRE ÉQUIPE", "On reste. Pas parce qu'on y est obligés. Parce qu'on a appris quelque chose."],
		["", "Vous vous tournez vers le Stagiaire Zéro et vous lui tendez le seul Contrat CDI du jeu."],
		[str(moi["nom"]).to_upper(), "Je te le dois depuis vingt ans."],
		["", "Il pose son mug. Le Directeur sourit, et signe un partenariat avec l'EEMI."],
		["", "Dernière image : votre siège plein à craquer. Gérard sert le café à tout le monde."],
		[str(moi["nom"]).to_upper(), "Finalement, la meilleure façon de recruter des alternants… c'est de bien les traiter."],
	]

func _fin_exploiteuse() -> Array:
	return [
		["", "Le Directeur soupire et vous laisse passer. Vous signez trente contrats d'un coup."],
		["", "Moustache Corp devient la plus grosse entreprise de Lyon."],
		["", "Le lendemain, en arrivant au bureau… tout est vide. Même Gérard est parti."],
		["UN MOT SUR VOTRE FAUTEUIL", "On est tous passés freelance. Bisous. — Ton équipe."],
		["", "À côté, un mug ébréché."],
		["", "Au loin, un TGV repart de Perrache. Vous êtes reparti·e à Paris. Seul·e."],
	]
