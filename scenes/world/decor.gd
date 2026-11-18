class_name DecorCarte
extends TileMapLayer
## La couche du decor (volumes tries en profondeur). Quand le joueur passe derriere
## un element haut - bord de toit, feuillage, tete de lampadaire - la partie qui le
## cache devient transparente, pour qu'on le voie toujours.

const OPACITE_DERRIERE := 0.35

## Cases rendues transparentes en ce moment.
var _transparentes: Dictionary = {}

## Rend transparentes, parmi ces cases, celles qui portent une partie haute.
func voir_a_travers(cases: Array[Vector2i]) -> void:
	var nouvelles := {}
	for c in cases:
		if get_cell_source_id(c) != -1 and _est_haute(get_cell_atlas_coords(c)):
			nouvelles[c] = true
	if nouvelles.size() == _transparentes.size() and nouvelles.keys().all(func(k): return _transparentes.has(k)):
		return
	_transparentes = nouvelles
	notify_runtime_tile_data_update()

func _est_haute(tuile: Vector2i) -> bool:
	if tuile in [Zones.TOIT_HAUT, Zones.TOIT_HAUT_GAUCHE, Zones.TOIT_HAUT_DROITE]:
		return true
	for entree in Zones.DECORS_HAUT.values():
		if entree[1] == tuile:
			return true
	return false

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return _transparentes.has(coords)

func _tile_data_runtime_update(_coords: Vector2i, tile_data: TileData) -> void:
	tile_data.modulate = Color(1, 1, 1, OPACITE_DERRIERE)
