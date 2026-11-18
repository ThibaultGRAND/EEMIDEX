class_name Dialogues
extends RefCounted
## Ce que disent les alternants croises sur la carte, et ce que le patron peut
## leur repondre.
##
## Un dialogue est une liste de « temps ». Un temps est soit une replique :
##     {"texte": "...", "locuteur": "Thigoat"}
## soit une question a choix :
##     {"question": "...", "choix": [{"texte": "...", "reponse": "...",
##                                    "bienveillance": 1, "action": &"combat"}]}
## « bienveillance » est facultatif (0 par defaut), « action » aussi
## (&"rien" par defaut ; &"combat" lance le combat a la fin du dialogue).
##
## Le code de la carte ne connait aucun de ces textes : il deroule la liste.
## Ajouter un alternant bavard = ajouter une ligne a PLAINTES.

## Ce dont chaque alternant se plaint, la premiere fois qu'on l'aborde.
const PLAINTES := {
	&"thigoat": "Je code, je fais les visuels et je vais chercher les sandwichs. C'était dans la fiche de poste, ça ?",
	&"seb": "Trois semaines que je demande un deuxième écran. Trois semaines.",
	&"roulian": "On m'a dit « fais ce que tu veux ». J'ai fait ce que je voulais. On m'a dit non.",
	&"matiti": "Le brief a changé quatre fois depuis ce matin. Quatre.",
	&"e1000": "J'ai automatisé mon poste. Du coup on m'a donné celui d'à côté aussi.",
	&"palou": "Je gère les réseaux de la boîte depuis mon téléphone perso. Mon forfait pleure.",
	&"tortheo": "Je suis en alternance, pas en apnée. Enfin, je croyais.",
	&"cecissoussou": "On m'appelle « l'alternante ». Depuis huit mois. J'ai un prénom.",
	&"thomasu": "J'ai proposé un tableau de bord. Ils l'ont mis dans un fichier Excel.",
	&"paguera": "Rien ne me fait mal. Mais là, quand même, un peu.",
	&"thibouclier": "Je prends les coups pour toute l'équipe. Personne ne m'a rien demandé.",
	&"guignome": "J'ai dormi deux heures. Pas cette nuit : cette semaine.",
}

## La question posee apres la plainte, et les deux reponses possibles.
const QUESTION_PLAINTE := "Il attend visiblement une réponse."
const REPONSE_ECOUTE := {
	"texte": "L'écouter jusqu'au bout",
	"reponse": "Vous le laissez finir sans l'interrompre. Ça ne règle rien, mais ça change quelque chose.",
	"bienveillance": 1,
}
const REPONSE_FORMATEUR := {
	"texte": "« C'est formateur. »",
	"reponse": "Il hoche la tête. Il a déjà entendu la phrase. Plusieurs fois.",
	"bienveillance": -1,
}

## Ce qu'on peut faire d'un alternant, une fois qu'on lui a parle.
const QUESTION_CONTRAT := "Que faites-vous ?"
const CHOIX_CONTRAT := {
	"texte": "Lui proposer un contrat",
	"reponse": "",
	"action": &"combat",
}
const CHOIX_PARTIR := {
	"texte": "Le laisser travailler",
	"reponse": "Vous passez votre chemin. Il retourne à son écran.",
}

## Ce que dit un alternant deja aborde une fois.
const REDITES: Array[String] = [
	"Toujours là, oui.",
	"Pas de nouvelles du deuxième écran.",
	"On fait aller.",
	"C'est gentil de repasser.",
]

## Le dialogue complet d'un alternant. `deja_vu` : on lui a deja parle une fois,
## la plainte et son choix ne reviennent donc pas (sinon la Bienveillance se
## farmerait en boucle sur le meme PNJ).
static func pour(gone_id: StringName, nom: String, deja_vu: bool) -> Array:
	var temps: Array = []
	var plainte := String(PLAINTES.get(gone_id, ""))
	if deja_vu or plainte.is_empty():
		temps.append({"texte": REDITES.pick_random(), "locuteur": nom})
	else:
		temps.append({"texte": plainte, "locuteur": nom})
		temps.append({
			"question": QUESTION_PLAINTE,
			"choix": [REPONSE_ECOUTE, REPONSE_FORMATEUR],
		})
	temps.append({
		"question": QUESTION_CONTRAT,
		"choix": [CHOIX_CONTRAT, CHOIX_PARTIR],
	})
	return temps
