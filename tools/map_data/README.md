# tools/map_data

Données brutes de carte (GeoJSON, exports OpenStreetMap, extraits data.grandlyon.com)
et script de conversion. **Rien d'ici n'est chargé par le jeu** : ce dossier est exclu
de l'export (voir `export_presets.cfg`, `exclude_filter`).

## Ce qui reste à faire

Le script de conversion n'est pas écrit : son langage est à décider avec l'équipe
(Python ? GDScript en mode outil ? Node ?).

Ce qu'il doit faire :

1. prendre une emprise en latitude/longitude (une zone du MVP) ;
2. lire les données ouvertes correspondantes ;
3. produire une grille de tuiles 16×16 avec 4 catégories : route, bâtiment, eau, parc ;
4. écrire la grille dans un format que `scenes/world/` sait lire.

La grille générée est une **base** : l'équipe la retouche ensuite dans l'éditeur pour
ajouter les traboules, les passages et le décor.

Pour l'instant, les 3 zones du MVP sont des plans écrits à la main dans
`scenes/world/zones.gd` (placeholder, voir le README à la racine).

Noter chaque source et sa licence dans `assets/maps/SOURCES.md`.
