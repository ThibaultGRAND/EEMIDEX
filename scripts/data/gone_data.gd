class_name GoneData
extends Resource
## Fiche d'un Gone. Un fichier .tres par étudiant dans data/gones/.
## Ajouter un Gone = ajouter un .tres, sans toucher au code.
##
## RGPD / droit à l'image : ne jamais passer consentement_recu à true
## avant d'avoir l'accord écrit de l'étudiant (voir docs/consentement.md).
## Retirer un Gone = supprimer son .tres.

@export var id: StringName = &""
@export var display_name: String = "Gone"
@export_multiline var description: String = ""
@export var type: StringName = &"neutre"
## Animations du personnage, au format de Sebastien
## (assets/characters/<id>/<id>_frames.tres). Le combat y pioche l'image de
## face pour l'adversaire et celle de dos pour l'alternant du joueur.
@export var frames: SpriteFrames
## Couleur de repli tant que le sprite n'est pas dessiné.
@export var couleur: Color = Color(0.9, 0.77, 0.42)

@export_group("Stats de base")
@export_range(10, 250) var base_pv: int = 24
@export_range(1, 60) var base_attaque: int = 10
@export_range(1, 30) var base_defense: int = 10
@export_range(1, 30) var base_vitesse: int = 10

@export_group("Attaques")
@export var attaque_de_base: MoveData
@export var pouvoir_signature: MoveData

@export_group("Capture")
## Plus la valeur est haute, plus le Gone est facile à recruter.
@export_range(1, 100) var taux_capture: int = 45
@export var sauvage: bool = true

@export_group("Consentement")
@export var consentement_recu: bool = false
@export_multiline var note_consentement: String = ""
