# Sources des données de carte

La carte de Lyon est construite à partir de données ouvertes, puis simplifiée en tilemap
pixel art. Chaque jeu de données utilisé doit être listé ici **avec sa licence**, et
l'attribution doit apparaître dans les crédits du jeu.

| Jeu de données | Source | Licence | Attribution exigée | Utilisé pour |
| --- | --- | --- | --- | --- |
| Export Overpass du quartier de la Confluence (`tools/map_data/confluence_osm.json`, 18 nov. 2026) | OpenStreetMap (overpass-api.de) | ODbL 1.0 | « © les contributeurs d'OpenStreetMap » | bâtiments, voirie, voies ferrées et de tram, eau, parcs, arbres des 4 zones |
| Contours de la Saône et du Rhône (`tools/map_data/confluence_rivieres.json`, relations 7317123 et 11696008) | OpenStreetMap (overpass-api.de) | ODbL 1.0 | « © les contributeurs d'OpenStreetMap » | les deux fleuves |

## Attribution minimale à afficher dans les crédits

> © les contributeurs d'OpenStreetMap

## Rappels

- Les données brutes (GeoJSON et autres) restent dans `tools/map_data/` et ne sont
  **jamais** chargées par le jeu.
- Vérifier la licence de chaque jeu de données **avant** de l'utiliser
  (OpenStreetMap : ODbL ; data.grandlyon.com : licence variable selon le jeu).
- La géographie reste reconnaissable, pas exacte au mètre : la grille générée est
  retouchée à la main dans l'éditeur.
