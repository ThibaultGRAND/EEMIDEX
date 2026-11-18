# Sources des données de carte

La carte de Lyon est construite à partir de données ouvertes, puis simplifiée en tilemap
pixel art. Chaque jeu de données utilisé doit être listé ici **avec sa licence**, et
l'attribution doit apparaître dans les crédits du jeu.

| Jeu de données | Source | Licence | Attribution exigée | Utilisé pour |
| --- | --- | --- | --- | --- |
| *(à remplir au premier import)* | | | | |

## Attribution minimale à afficher dans les crédits

> © les contributeurs d'OpenStreetMap

## Rappels

- Les données brutes (GeoJSON et autres) restent dans `tools/map_data/` et ne sont
  **jamais** chargées par le jeu.
- Vérifier la licence de chaque jeu de données **avant** de l'utiliser
  (OpenStreetMap : ODbL ; data.grandlyon.com : licence variable selon le jeu).
- La géographie reste reconnaissable, pas exacte au mètre : la grille générée est
  retouchée à la main dans l'éditeur.
