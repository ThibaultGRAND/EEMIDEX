class_name ItemData
extends Resource
## Un objet utilisable en combat ou sur la carte. Un .tres par objet dans data/items/.

enum Genre { SOIN, CAPTURE, BOOST }

@export var id: StringName = &""
@export var display_name: String = "Objet"
@export_multiline var description: String = ""
@export var genre: Genre = Genre.SOIN
## SOIN : PV rendus. CAPTURE : bonus de capture en %. BOOST : points de stat.
@export var valeur: int = 20
@export var utilisable_en_combat: bool = true
