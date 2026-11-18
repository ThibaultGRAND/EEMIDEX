# CLAUDE.md — Gones (nom de travail)

Jeu façon Pokémon dans un Lyon en pixel art, jouable dans le navigateur. Le joueur est une Moustache ou une Moustachette. Les créatures (« Gones ») sont les étudiants de la promo. Projet de cours.

Le document de référence est la page de cadrage. En cas de doute sur le périmètre, demande avant de coder.

## Stack

- Godot 4.x (version figée pour toute l'équipe : **4.7.2 stable**), en GDScript uniquement.
- Cible principale : export Web (HTML5/WebAssembly). Tout ce qui ne marche pas en Web est exclu.

## Règles Godot

### Langage et style
- GDScript seulement. Pas de C# (non supporté par l'export Web de Godot 4) ni de GDExtension.
- Typage statique partout : `var hp: int = 10`, `func take_damage(amount: int) -> void:`.
- Respecter le style guide officiel de GDScript :
  - fichiers et dossiers en `snake_case` (`battle_manager.gd`, `battle_screen.tscn`) ;
  - `class_name` et noms de nœuds en `PascalCase` ;
  - variables et fonctions en `snake_case`, constantes en `CONSTANT_CASE` ;
  - ordre dans un script : `class_name`, `extends`, signaux, enums, constantes, `@export`, variables, `_ready`, autres fonctions.
- Indentation : tabulations (défaut Godot).

### Architecture
- Un seul autoload : `GameState` (équipe, inventaire, progression, sauvegarde). N'en ajoute pas d'autre sans demander.
- Communication entre scènes par **signaux**. Pas de chaînes `get_node("../../X")`.
- Références aux nœuds : `@onready var x: Node = %UniqueName` ou `@export`. Pas de chemins en dur fragiles.
- Données de jeu dans des `Resource` (`.tres`), pas dans le code :
  - `data/gones/` : un `.tres` par étudiant (classe `GoneData`) ;
  - `data/moves/` : attaques et pouvoirs (classe `MoveData`) ;
  - `data/items/` : objets (classe `ItemData`).
  Ajouter un Gone ne doit jamais demander de toucher au code.
- Une scène = une responsabilité. Le combat ne connaît pas la carte, les mini-jeux ne connaissent pas le combat : ils renvoient un résultat par signal.
- Entrées clavier via l'InputMap (`ui_accept`, `move_up`…), jamais via des keycodes en dur.

### Fichiers à ne pas toucher
- Ne jamais modifier `.godot/`, les fichiers `.import` ni les `.uid`. Committer les `.uid`, ignorer `.godot/`.
- Les `.tscn` et `.tres` : modifications minimales et ciblées. Pour une nouvelle scène complexe, propose la structure de nœuds et laisse l'équipe la construire dans l'éditeur. Après toute édition d'un `.tscn`, signale qu'il faut l'ouvrir dans l'éditeur pour vérifier.

### Pixel art
- **Résolution de base : 320×180. Tuiles de 16×16. Décidé le 18 nov. 2026, ne pas y revenir
  sans l'accord de l'équipe.** Stretch mode `viewport`, scale `integer`.
- Tailles imposées, valables pour tout le monde :

  | Élément | Taille |
  | --- | --- |
  | Écran | 320 × 180 pixels |
  | Tuile | 16 × 16 |
  | Personnage | 16 à 20 de large, 24 à 32 de haut |
  | Objet posé au sol | 16 × 16 |
  | Bâtiment | multiple de 16, 2 à 3 cases de haut |

  Un asset livré à une autre échelle est à refaire : réduire du pixel art le détruit.
- **Vue de dessus en 3/4** (style Pokémon DS), pas vue de dessus à plat. Voir
  `docs/direction-artistique.md` : Y-sort obligatoire, caméra qui suit le joueur,
  personnages de 24 à 32 px de haut, origine des sprites aux pieds.
- Filtre de texture par défaut : `Nearest`. Pas de mipmaps.
- Tuiles de 16×16 px. Carte construite avec `TileMapLayer` (pas l'ancien nœud `TileMap`, déprécié).

### Contraintes Web
- Export sans threads (option disponible depuis Godot 4.3) : pas de headers COOP/COEP à configurer.
- Sauvegarde uniquement dans `user://` (IndexedDB côté navigateur). Aucun accès à d'autres chemins.
- Pas d'API spécifiques à un OS (`OS.execute`, système de fichiers local…).
- Audio : `.ogg`. Le son ne démarre qu'après une première interaction du joueur (règle des navigateurs).
- Garder le poids du build raisonnable : pas d'assets inutilisés dans le projet.

### Vérification
- Avant de dire qu'une tâche est terminée : le projet s'ouvre sans erreur et la scène concernée se lance.
- Export Web en ligne de commande (preset nommé `Web`) :
  `godot --headless --export-release "Web" build/web/index.html`
- Si une commande ou une API Godot est incertaine, vérifie dans la doc de la version utilisée. N'invente pas d'API.

## Carte de Lyon : données publiques

La carte est construite à partir de données ouvertes, puis simplifiée en tilemap pixel art. On ne dessine pas Lyon de mémoire.

- Sources :
  - **OpenStreetMap** (licence ODbL) : rues, bâtiments, parcs, cours d'eau ;
  - **data.grandlyon.com** (open data de la Métropole de Lyon) : voirie, espaces verts, lieux remarquables.
- Vérifier la licence de **chaque** jeu de données avant usage, et la noter dans `assets/maps/SOURCES.md`.
- Attribution obligatoire dans les crédits du jeu, au minimum « © les contributeurs d'OpenStreetMap ».
- Les données brutes (GeoJSON, etc.) restent dans `tools/map_data/` et ne sont **pas** chargées par le jeu.
- Un script de conversion dans `tools/` transforme une zone (emprise en lat/lon) en grille de tuiles 16×16 : route, bâtiment, eau, parc. Le langage du script est à décider avec l'équipe.
- La grille générée sert de base ; l'équipe retouche ensuite à la main dans l'éditeur (traboules, passages, décor). La géographie reste reconnaissable, pas exacte au mètre.
- Zones du MVP : Presqu'île (Bellecour), Vieux Lyon, Fourvière.

## Arborescence

```
res://
├── scenes/
│   ├── world/        # zones (TileMapLayer), joueur
│   ├── battle/       # écran de combat
│   ├── minigames/    # un sous-dossier par mini-jeu
│   └── ui/           # menus, inventaire, dialogues
├── scripts/
│   └── autoload/     # game_state.gd
├── data/
│   ├── gones/
│   ├── moves/
│   └── items/
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   ├── maps/         # SOURCES.md des données de carte
│   └── audio/
└── tools/            # hors jeu : conversion des données de carte
    └── map_data/
```

## Règles du projet

- Aucun Gone sans l'accord écrit de l'étudiant concerné. Un étudiant qui refuse est remplacé par un Gone générique.
- Les sprites et le pixel art sont faits par l'équipe. Claude ne génère pas d'assets graphiques, sauf placeholders explicitement marqués `placeholder_`.
- Rester dans le périmètre MVP (3 zones, 8 à 12 Gones, combat 1 contre 1, 2 mini-jeux, 1 sauvegarde). Toute fonctionnalité en plus : la proposer, ne pas la coder.
- Pas d'addon ni de plugin de l'Asset Library sans validation de l'équipe.
- Changements petits et ciblés. Un commit = une modification compréhensible.

METS TOUJOURS A JOUR LE CLAUDE.MD POUR LES REGLES ET LAVANCE

---

## Avancement

*Mis à jour le 18 nov. 2026.*

### Ce qui existe

Squelette jouable de bout en bout, avec des formes de couleur en guise de graphismes.
Seul le joueur a un vrai sprite ; pas encore de tileset dessiné, aucun son.

- `scripts/autoload/game_state.gd` — l'autoload unique : équipe (3 max), sac, 3 ressources,
  drapeaux de progression, catalogues chargés depuis `data/`, sauvegarde JSON dans `user://`.
- `scripts/data/` — `GoneData`, `MoveData`, `ItemData` (Resources) et `GoneInstance`
  (le Gone en cours de partie : niveau, PV, bonus gagnés aux mini-jeux).
- `scenes/world/` — carte case par case, 3 zones reliées (Presqu'île, Vieux Lyon,
  Fourvière), traboules, ressources au sol, soin, boutique, salle d'entraînement,
  rencontres aléatoires dans l'herbe, menu pause et sauvegarde.
- `assets/sprites/joueur_moustache.png` — le joueur (la Moustache), utilisé par
  `scenes/world/player.tscn` à la place de `placeholder_joueur.png` : 2 foulées × 4
  directions (bas, haut, gauche, droite), cases de 32×36, perso de 32 px de haut. Réduit
  depuis la planche 8 directions fournie par l'équipe.
- `scenes/world/pnj.tscn` + `pnj.gd` — PNJ qui se baladent case par case autour de leur
  case de départ (rayon 3), sur les sols listés dans `Zones.SOLS_PNJ`. Le PNJ émet
  `envie_de_bouger`, `world.gd` choisit la case ; joueur et PNJ se bloquent mutuellement.
  Placement par zone dans `zones.gd` (clé `"pnj"`) ; sprites `assets/sprites/pnj_*.png`
  (2 foulées × 4 directions, perso de 30 px). Pour l'instant : 4 PNJ à la Presqu'île.
- `scenes/battle/` — combat 1 contre 1 au tour par tour : attaquer / objet / changer /
  fuir, ordre selon la vitesse, capture au Filet à Gone, combat de fin à Fourvière.
- `scenes/minigames/rythme/` (vitesse) et `scenes/minigames/frappe/` (attaque).
- `data/` — 5 Gones génériques, 7 attaques, 3 objets, plus `_modele_etudiant.tres`.
- `export_presets.cfg` — preset `Web`, **sans threads**. `.github/workflows/export-web.yml`
  exporte et publie sur GitHub Pages à chaque push sur `main`.

### Décisions provisoires, à confirmer en équipe

| Question ouverte du cadrage | Choix provisoire |
| --- | --- |
| Nom des créatures | Gones |
| Quels 2 mini-jeux | Rythme (vitesse) et Frappe chronométrée (attaque) |
| Version de Godot | **4.7.2 stable** (installée le 18 nov. 2026, à confirmer avec l’équipe) |
| Ressources | praline (Presqu'île), cocon (Vieux Lyon), quenelle (Fourvière) |
| Histoire et objectif final | non écrits : le MVP s'arrête au gardien de Fourvière |

Le cocon n'a pas encore de mini-jeu : il ne sert qu'à la boutique, en attendant une
éventuelle décision sur un troisième mini-jeu (esquive, pour la défense).

### Écarts assumés aux règles ci-dessus

- **Pas de `TileMapLayer`** : sans tileset dessiné, les 3 zones sont des plans en texte
  dans `scenes/world/zones.gd`, rendus par `_draw()`. C'est un placeholder explicite.
  Quand les tuiles 16×16 existeront, remplacer `_draw()` par une `TileMapLayer` ;
  les plans texte restent une bonne base de travail.
- **Pas de script de conversion des données de carte** : le langage n'est pas décidé.
  `tools/map_data/README.md` dit ce qu'il doit faire.
- **`placeholder_icon.svg`** est le seul asset graphique généré, marqué comme tel.
- Les changements de scène passent par `get_tree().change_scene_to_file()` avec les
  constantes de `GameState`. Les mini-jeux et le combat n'appellent jamais la carte
  directement : ils écrivent leur résultat dans `GameState` et rendent la main.

### Démo de personnages (hors jeu)

Prototype isolé, **non branché au jeu** : `scenes/main.tscn` (+ `scenes/pnj_*.tscn`,
`scripts/main.gd`, `scripts/pnj.gd`, `assets/characters/`). Quatre PNJ (PnjSeb, PnjThomas, PnjJulian, PnjPaloma) en
8 directions, découpés depuis des planches fournies par l'équipe (fond vert ou magenta détouré).
Les sprites font environ 176 px de haut : leur taille n'est pas encore calée sur l'échelle du jeu.
Reste à faire avant de les brancher au jeu :

- pas encore de suivi de consentement pour les personnes représentées ;
- touches codées en dur (Maj, Tab) au lieu de l'InputMap ;
- dossier `assets/characters/` au lieu de `assets/sprites/`.

### Reste à faire pour le MVP

- [x] Figer la version de Godot : **4.7.2 stable** (`project.godot` et la CI sont alignés)
- [ ] Collecter les consentements (voir `docs/consentement.md`), puis créer les 8 à 12 Gones
- [x] Passer la carte en `TileMapLayer` avec Y-sort, caméra qui suit, déplacement glissé
- [ ] Dessiner les vraies tuiles **à 16 px** et remplacer les placeholders
- [ ] Redessiner les personnages **à 24-32 px de haut** (ceux de la démo font 176 px)
- [ ] Écrire le script de découpage des planches de sprites
- [ ] Décider le script de conversion des données ouvertes et remplir `assets/maps/SOURCES.md`
- [ ] Équilibrer stats, niveaux, taux de capture
- [ ] Dialogues, histoire, objectif final
- [ ] Musique et sons libres de droits (`.ogg`)
- [ ] Vérifier l'export Web en ligne (GitHub Pages ou itch.io)
